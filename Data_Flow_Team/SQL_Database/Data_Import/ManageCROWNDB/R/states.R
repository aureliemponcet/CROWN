ImportStates <- function(){ # begin function

  # ----- Complete Log File -----

  loginfo("Table: states", logger = "")
  loginfo(paste("Time ini:", Sys.time()), logger="")


  # ----- Import data from rda file ----

  data(states) # import data from rda file

  # ----- Import data into database -----

  con <- ConnectToDB() # connect to postgresql database
  on.exit(dbDisconnect(con)) # on exit, close connection

  states <- within(states, state <- as.character(state)) # convert code to character

  # query the data from codes table
  query <- as.data.frame(dbGetQuery(con, "SELECT * from states"))

  if (NROW(query) > 0){
    states <- as.data.frame(states[states$state %in% query$state == FALSE,])
    colnames(states) <- "state"
  }

  if(NROW(states) > 0){

    # add data into database
    dbWriteTable(con, "states", value = states, append=T, row.names=F)

    loginfo("ADDED", logger = "") # complete log file
    loginfo(c(states), logger = "") # complete log file
  }

  loginfo("Table: states", logger = "")
  loginfo(paste("Time end:", Sys.time()), logger="")


} # end function
