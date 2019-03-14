ImportCashCrops <- function(){ # begin ImportCodes() function

  # ----- Complete Log File -----

  loginfo("Table: cash_crops", logger = "")
  loginfo(paste("Time ini:", Sys.time()), logger="")


  # ----- Import Cash Crops from rda file -----

  data(cashcrops) # import data from rda file

  # ----- Import data into database -----

  con <- ConnectToDB() # connect to postgresql database
  on.exit(dbDisconnect(con)) # on exit, close connection

  cashcrops <- within(cashcrops, cash_crop <- as.character(cash_crop)) # convert code to character

  # query the data from codes table
  query <- as.data.frame(dbGetQuery(con, "SELECT * from cash_crops"))


  if (NROW(query) > 0){ #
    cashcrops <- as.data.frame(cashcrops[cashcrops$cash_crop %in% query$cash_crop == FALSE,])
    colnames(cashcrops) <- "cash_crop"
  }

  if(NROW(cashcrops) > 0){

    # add data into database
    dbWriteTable(con, "cash_crops", value = cashcrops, append=T, row.names=F)

    loginfo("ADDED", logger = "") # complete log file
    loginfo(c(cashcrops), logger = "") # complete log file
  }

  loginfo("Table: cash_crops", logger = "")
  loginfo(paste("Time end:", Sys.time()), logger="")


} # end ImportCodes() function
