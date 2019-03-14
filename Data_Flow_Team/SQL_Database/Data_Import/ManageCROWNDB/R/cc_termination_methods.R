ImportCCTerminationMethods <- function(){ # begin function

  # ----- Complete Log File -----

  loginfo("Table: cc_termination_methods", logger = "")
  loginfo(paste("Time ini:", Sys.time()), logger="")


  # ----- Import data from rda file ----

  data(ccterminationmethods) # import data from rda file

  # ----- Import data into database -----

  con <- ConnectToDB() # connect to postgresql database
  on.exit(dbDisconnect(con)) # on exit, close connection

  ccterm <- within(ccterm, cc_termination_method <- as.character(cc_termination_method)) # convert code to character

  # query the data from codes table
  query <- as.data.frame(dbGetQuery(con, "SELECT * from cc_termination_methods"))


  if (NROW(query) > 0){ #
    ccterm <- as.data.frame(ccterm[ccterm$cc_termination_method %in% query$cc_termination_method == FALSE,])
    colnames(ccterm) <- "cc_termination_method"
  }


  if(NROW(ccterm) > 0){

    # add data into database
    dbWriteTable(con, "cc_termination_methods", value = ccterm, append=T, row.names=F)

    loginfo("ADDED", logger = "") # complete log file
    loginfo(c(ccterm), logger = "") # complete log file

  }

  loginfo("Table: cc_termination_methods", logger = "")
  loginfo(paste("Time end:", Sys.time()), logger="")


} # end function
