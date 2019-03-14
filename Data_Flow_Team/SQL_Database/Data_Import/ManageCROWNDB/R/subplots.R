ImportSubplots <- function(){ # begin function

  # ----- Complete Log File -----

  loginfo("Table: subplots", logger = "")
  loginfo(paste("Time ini:", Sys.time()), logger="")


  # ----- Import data from rda file ----

  data(subplots) # import data from rda file

  # ----- Import data into database -----

  con <- ConnectToDB() # connect to postgresql database
  on.exit(dbDisconnect(con)) # on exit, close connection

  subplots <- within(subplots, subplot <- as.character(subplot)) # convert code to character

  # query the data from codes table
  query <- as.data.frame(dbGetQuery(con, "SELECT * from subplots"))

  if (NROW(query) > 0){
    subplots <- as.data.frame(subplots[subplots$subplot %in% query$subplot == FALSE,])
    colnames(subplots) <- "subplot"
  }

  if(NROW(subplots) > 0){

    # add data into database
    dbWriteTable(con, "subplots", value = subplots, append=T, row.names=F)

    loginfo("ADDED", logger = "") # complete log file
    loginfo(c(subplots), logger = "") # complete log file
  }

  loginfo("Table: subplots", logger = "")
  loginfo(paste("Time end:", Sys.time()), logger="")


} # end function
