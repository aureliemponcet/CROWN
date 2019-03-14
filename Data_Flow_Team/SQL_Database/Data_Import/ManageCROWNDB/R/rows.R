ImportRows <- function(){ # begin function

  # ----- Complete Log File -----

  loginfo("Table: rows", logger = "")
  loginfo(paste("Time ini:", Sys.time()), logger="")


  # ----- Import data from rda file ----

  data(rows) # import data from rda file

  # ----- Import data into database -----

  con <- ConnectToDB() # connect to postgresql database
  on.exit(dbDisconnect(con)) # on exit, close connection

  rows <- within(rows, row <- as.character(row)) # convert code to character

  # query the data from codes table
  query <- as.data.frame(dbGetQuery(con, "SELECT * from rows"))

  if (NROW(query) > 0){
    rows <- as.data.frame(rows[rows$row %in% query$row == FALSE,])
    colnames(rows) <- "row"
  }

  if(NROW(rows) > 0){

    # add data into database
    dbWriteTable(con, "rows", value = rows, append=T, row.names=F)

    loginfo("ADDED", logger = "") # complete log file
    loginfo(c(rows), logger = "") # complete log file
  }

  loginfo("Table: rows", logger = "")
  loginfo(paste("Time end:", Sys.time()), logger="")


} # end function
