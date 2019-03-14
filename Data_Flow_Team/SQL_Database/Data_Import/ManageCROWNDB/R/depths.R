ImportDepths <- function(){ # begin function

  # ----- Complete Log File -----

  loginfo("Table: depths", logger = "")
  loginfo(paste("Time ini:", Sys.time()), logger="")


  # ----- Import data from rda file ----

  data(depths) # import data from rda file

  # ----- Import data into database -----

  con <- ConnectToDB() # connect to postgresql database
  on.exit(dbDisconnect(con)) # on exit, close connection

  depths <- within(depths, depth <- as.character(depth)) # convert code to character

  # query the data from codes table
  query <- as.data.frame(dbGetQuery(con, "SELECT * from depths"))


  if (NROW(query) > 0){
   depths <- as.data.frame(depths[depths$depth %in% query$depth == FALSE,])
    colnames(depths) <- "depths"
  }

  if(NROW(depths) > 0){

    # add data into database
    dbWriteTable(con, "depths", value = depths, append=T, row.names=F)

    loginfo("ADDED", logger = "") # complete log file
    loginfo(c(depths), logger = "") # complete log file
  }

  loginfo("Table: depths", logger = "")
  loginfo(paste("Time end:", Sys.time()), logger="")


} # end function
