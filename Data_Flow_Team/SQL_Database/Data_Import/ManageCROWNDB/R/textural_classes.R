ImportTexturalClasses <- function(){ # begin function

  # ----- Complete Log File -----

  loginfo("Table: textural_classes", logger = "")
  loginfo(paste("Time ini:", Sys.time()), logger="")

  # ----- Import data from rda file ----

  data(texturalclasses) # import data from rda file

  # ----- Import data into database -----

  con <- ConnectToDB() # connect to postgresql database
  on.exit(dbDisconnect(con)) # on exit, close connection

  tclass <- within(tclass, tclass <- as.character(tclass)) # convert code to character

  # query the data from codes table
  query <- as.data.frame(dbGetQuery(con, "SELECT * from textural_classes"))

  if (NROW(query) > 0){
    tclass <- as.data.frame(tclass[tclass$tclass %in% query$tclass == FALSE,])
    colnames(tclass) <- "tclass"
  }

  if(NROW(tclass) > 0){

    # add data into database
    dbWriteTable(con, "textural_classes", value = tclass, append=T, row.names=F)

    loginfo("ADDED", logger = "") # complete log file
    loginfo(c(tclass), logger = "") # complete log file
  }

  loginfo("Table: textural_classes", logger = "")
  loginfo(paste("Time end:", Sys.time()), logger="")


} # end function
