ImportCCPlantingMethods <- function(){ # begin function

  # ----- Complete Log File -----

  loginfo("Table: cc_planting_methods", logger = "")
  loginfo(paste("Time ini:", Sys.time()), logger="")


  # ----- Import Cash Crops from rda file ----

  data(ccplantingmethods) # import data from rda file

  # ----- Import data into database -----

  con <- ConnectToDB() # connect to postgresql database
  on.exit(dbDisconnect(con)) # on exit, close connection

  ccplant <- within(ccplant, cc_planting_method <- as.character(cc_planting_method)) # convert code to character

  # query the data from codes table
  query <- as.data.frame(dbGetQuery(con, "SELECT * from cc_planting_methods"))


  if (NROW(query) > 0){ #
    ccplant <- as.data.frame(ccplant[ccplant$cc_planting_method %in% query$cc_planting_method == FALSE,])
    colnames(ccplant) <- "cc_planting_method"
  }


  if(NROW(ccplant) > 0){

    # add data into database
    dbWriteTable(con, "cc_planting_methods", value = ccplant, append=T, row.names=F)

    loginfo("ADDED", logger = "") # complete log file
    loginfo(c(ccplant), logger = "") # complete log file
  }

  loginfo("Table: cc_planting_methods", logger = "")
  loginfo(paste("Time end:", Sys.time()), logger="")


} # end function
