ImportSeasons <- function(){ # begin function

  # ----- Complete Log File -----

  loginfo("Table: seasons", logger = "")
  loginfo(paste("Time ini:", Sys.time()), logger="")


  # ----- Import data from rda file ----

  data(seasons) # import data from rda file

  # ----- Import data into database -----

  con <- ConnectToDB() # connect to postgresql database
  on.exit(dbDisconnect(con)) # on exit, close connection

  seasons <- within(seasons, season <- as.character(season)) # convert code to character

  # query the data from codes table
  query <- as.data.frame(dbGetQuery(con, "SELECT * from seasons"))

  if (NROW(query) > 0){
    seasons <- as.data.frame(seasons[seasons$season %in% query$season == FALSE,])
    colnames(seasons) <- "season"
  }

  if(NROW(seasons) > 0){

    # add data into database
    dbWriteTable(con, "seasons", value = seasons, append=T, row.names=F)

    loginfo("ADDED", logger = "") # complete log file
    loginfo(c(seasons), logger = "") # complete log file
  }

  loginfo("Table: seasons", logger = "")
  loginfo(paste("Time end:", Sys.time()), logger="")


} # end function
