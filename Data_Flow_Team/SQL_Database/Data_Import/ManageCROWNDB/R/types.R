ImportTypes <- function(){ # begin function

  # ----- Complete Log File -----

  loginfo("Table: types", logger = "")
  loginfo(paste("Time ini:", Sys.time()), logger="")

  # ----- Import data from rda file ----

  data(types) # import data from rda file

  # ----- Import data into database -----

  con <- ConnectToDB() # connect to postgresql database
  on.exit(dbDisconnect(con)) # on exit, close connection

  types <- within(types, type <- as.character(type)) # convert code to character

  # query the data from codes table
  query <- as.data.frame(dbGetQuery(con, "SELECT * from types"))

  if (NROW(query) > 0){
    types <- as.data.frame(types[types$type %in% query$type == FALSE,])
    colnames(types) <- "type"
  }

  if(NROW(types) > 0){

    # add data into database
    dbWriteTable(con, "types", value = types, append=T, row.names=F)

    loginfo("ADDED", logger = "") # complete log file
    loginfo(c(types), logger = "") # complete log file
  }

  loginfo("Table: types", logger = "")
  loginfo(paste("Time end:", Sys.time()), logger="")


} # end function
