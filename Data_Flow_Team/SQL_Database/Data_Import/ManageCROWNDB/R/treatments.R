ImportTreatments <- function(){ # begin function

  # ----- Complete Log File -----

  loginfo("Table: treatments", logger = "")
  loginfo(paste("Time ini:", Sys.time()), logger="")

  # ----- Import data from rda file ----

  data(treatments) # import data from rda file

  # ----- Import data into database -----

  con <- ConnectToDB() # connect to postgresql database
  on.exit(dbDisconnect(con)) # on exit, close connection

  treatments <- within(treatments, treatment <- as.character(treatment)) # convert code to character

  # query the data from codes table
  query <- as.data.frame(dbGetQuery(con, "SELECT * from treatments"))

  if (NROW(query) > 0){
    treatments <- as.data.frame(treatments[treatments$treatment %in% query$treatment == FALSE,])
    colnames(treatments) <- "treatment"
  }

  if(NROW(treatments) > 0){

    # add data into database
    dbWriteTable(con, "treatments", value = treatments, append=T, row.names=F)

    loginfo("ADDED", logger = "") # complete log file
    loginfo(c(treatments), logger = "") # complete log file
  }

  loginfo("Table: treatments", logger = "")
  loginfo(paste("Time end:", Sys.time()), logger="")


} # end function
