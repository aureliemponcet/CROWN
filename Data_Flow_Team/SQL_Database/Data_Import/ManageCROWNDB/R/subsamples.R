ImportSubsamples <- function(){ # begin function

  # ----- Complete Log File -----

  loginfo("Table: subsamples", logger = "")
  loginfo(paste("Time ini:", Sys.time()), logger="")


  # ----- Import data from rda file ----

  data(subsamples) # import data from rda file

  # ----- Import data into database -----

  con <- ConnectToDB() # connect to postgresql database
  on.exit(dbDisconnect(con)) # on exit, close connection

  subsamples <- within(subsamples, subsample <- as.character(subsample)) # convert code to character

  # query the data from codes table
  query <- as.data.frame(dbGetQuery(con, "SELECT * from subsamples"))

  if (NROW(query) > 0){
    subsamples <- as.data.frame(subsamples[subsamples$subsample %in% query$subsample == FALSE,])
    colnames(subsamples) <- "subsample"
  }

  if(NROW(subsamples) > 0){

    # add data into database
    dbWriteTable(con, "subsamples", value = subsamples, append=T, row.names=F)

    loginfo("ADDED", logger = "") # complete log file
    loginfo(c(subsamples), logger = "") # complete log file
  }

  loginfo("Table: subsamples", logger = "")
  loginfo(paste("Time end:", Sys.time()), logger="")


} # end function
