ImportCodes <- function(){ # begin ImportCodes() function

  # ----- Complete Log File -----

  loginfo("Table: codes", logger = "")
  loginfo(paste("Time ini:", Sys.time()), logger="")


  # ----- Create all possible 3-letter codes -----

  codes <- crossing(LETTERS,LETTERS,LETTERS)  # calculate all possible combinations
  codes.vector <- c() # create an empty list

  for(row in 1:NROW(codes)){ # begin iteration over row
    codes.vector <- c(codes.vector,paste(codes[row,1],codes[row,2],codes[row,3], sep="")) # concatenate codes
  } # end iteration over row

  codes <- data.frame(code = codes.vector) # store all possible three letter codes in table
  rm(codes.vector); rm(row) # clean workspace

  # ----- Import data into database -----

  con <- ConnectToDB() # connect to postgresql database
  on.exit(dbDisconnect(con)) # on exit, close connection

  codes <- within(codes, code <- as.character(code)) # convert code to character

  # query the data from codes table
  query <- as.data.frame(dbGetQuery(con, "SELECT * from codes"))

  if (NROW(query) > 0){ #
    codes <- as.data.frame(codes[codes$code %in% query$code == FALSE,])
    colnames(codes) <- "code"
  }

  if(NROW(codes) > 0){
  # add data into database
  dbWriteTable(con, "codes", value = codes, append=T, row.names=F)

  loginfo("ADDED", logger = "") # complete log file
  loginfo(c(codes), logger = "") # complete log file
  }

  loginfo("Table: codes", logger = "")
  loginfo(paste("Time end:", Sys.time()), logger="")


 } # end ImportCodes() function
