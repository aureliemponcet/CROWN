ImportChemicalFamilies <- function(){ # begin function

  # ----- Complete Log File -----

  loginfo("Table: chemical_families", logger = "")
  loginfo(paste("Time ini:", Sys.time()), logger="")

  # ----- Import data from rda file ----

  data(chemicalfamilies) # import data from rda file

  # ----- Import data into database -----

  con <- ConnectToDB() # connect to postgresql database
  on.exit(dbDisconnect(con)) # on exit, close connection

  chemfam <- within(chemfam, chemical_family <- as.character(chemical_family)) # convert code to character

  # query the data from codes table
  query <- as.data.frame(dbGetQuery(con, "SELECT * from chemical_families"))

  if (NROW(query) > 0){
    chemfam <- as.data.frame(chemfam[chemfam$chemical_family %in% query$chemical_family == FALSE,])
    colnames(chemfam) <- "chemical_family"
  }

  if(NROW(chemfam) > 0){

    # add data into database
    dbWriteTable(con, "chemical_families", value = chemfam, append=T, row.names=F)

    loginfo("ADDED", logger = "") # complete log file
    loginfo(c(chemfam), logger = "") # complete log file
  }

  loginfo("Table: chemical_families", logger = "")
  loginfo(paste("Time end:", Sys.time()), logger="")


} # end function
