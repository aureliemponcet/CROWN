ImportTimes <- function(){ # begin function

  # ----- Complete Log File -----

  loginfo("Table: times", logger = "")
  loginfo(paste("Time ini:", Sys.time()), logger="")

  # ----- Import data from rda file ----

  data(times) # import data from rda file

  # ----- Import data into database -----

  con <- ConnectToDB() # connect to postgresql database
  on.exit(dbDisconnect(con)) # on exit, close connection

  times <- within(times, time <- as.character(time)) # convert code to character

  # query the data from codes table
  query <- as.data.frame(dbGetQuery(con, "SELECT * from times"))

  if (NROW(query) > 0){
    times <- as.data.frame(times[times$time %in% query$time == FALSE,])
    colnames(times) <- "time"
  }

  if(NROW(times) > 0){

    # add data into database
    dbWriteTable(con, "times", value = times, append=T, row.names=F)

    loginfo("ADDED", logger = "") # complete log file
    loginfo(c(times), logger = "") # complete log file
  }

  loginfo("Table: times", logger = "")
  loginfo(paste("Time end:", Sys.time()), logger="")


} # end function
