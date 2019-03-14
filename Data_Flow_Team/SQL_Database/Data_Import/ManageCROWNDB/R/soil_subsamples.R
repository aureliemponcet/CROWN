ImportSoilSubsamples <- function(){ # begin function

  # ----- Complete Log File -----

  loginfo("Table: soil_subsamples", logger = "")
  loginfo(paste("Time ini:", Sys.time()), logger="")


  # ----- Import data from rda file ----

  data(soilsubsample) # import data from rda file

  # ----- Import data into database -----

  con <- ConnectToDB() # connect to postgresql database
  on.exit(dbDisconnect(con)) # on exit, close connection

  ssub <- within(ssub, ssubsample <- as.character(ssubsample)) # convert code to character

  # query the data from codes table
  query <- as.data.frame(dbGetQuery(con, "SELECT * from soil_subsamples"))

  if (NROW(query) > 0){
    ssub <- as.data.frame(ssub[ssub$ssubsample %in% query$ssubsample== FALSE,])
    colnames(ssub) <- "ssubsample"
  }

  if(NROW(ssub) > 0){

    # add data into database
    dbWriteTable(con, "soil_subsamples", value = ssub, append=T, row.names=F)

    loginfo("ADDED", logger = "") # complete log file
    loginfo(c(ssub), logger = "") # complete log file
  }

  loginfo("Table: soil_subsamples", logger = "")
  loginfo(paste("Time end:", Sys.time()), logger="")


} # end function
