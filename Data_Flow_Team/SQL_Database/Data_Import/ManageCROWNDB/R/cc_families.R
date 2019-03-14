ImportCCFamilies <- function(){ # begin ImportCodes() function

  # ----- Complete Log File -----

  loginfo("Table: cc_families", logger = "")
  loginfo(paste("Time ini:", Sys.time()), logger="")


  # ----- Import Cash Crops from rda file ----

  data(ccfamilies) # import data from rda file

  # ----- Import data into database -----

  con <- ConnectToDB() # connect to postgresql database
  on.exit(dbDisconnect(con)) # on exit, close connection

  ccfamilies <- within(ccfamilies, cc_family <- as.character(cc_family)) # convert code to character

  # query the data from codes table
  query <- as.data.frame(dbGetQuery(con, "SELECT * from cc_families"))


  if (NROW(query) > 0){ #
    ccfamilies <- as.data.frame(ccfamilies[ccfamilies$cc_family %in% query$cc_family == FALSE,])
    colnames(ccfamilies) <- "cc_family"
  }

  if(NROW(ccfamilies) > 0){

    # add data into database
    dbWriteTable(con, "cc_families", value = ccfamilies, append=T, row.names=F)

    loginfo("ADDED", logger = "") # complete log file
    loginfo(c(ccfamilies), logger = "") # complete log file
  }

  loginfo("Table: cc_families", logger = "")
  loginfo(paste("Time end:", Sys.time()), logger="")


} # end ImportCodes() function
