ImportSiteInfo <- function(){ # begin function to import producer_ids

  # ----- Complete Log File -----

  loginfo("Table: site_information", logger = "")
  loginfo(paste("Time ini:", Sys.time()), logger="")

  # ----- Connect to postgresql database -----

  con <- ConnectToDB() # connect to postgresql database
  on.exit(dbDisconnect(con)) # on exit, close connection

  # ----- Import data from Google Spreadsheet -----

  # import data from google sheet
  keys <- c("1DXVi4MaEvZ_UbNu-pcT5skeb_4GfMCqS4cNkb494-OE",  # GA2018
            "1Az_8qAfpjVta9vXZFhr3YTsxSsLGHQmGTsPU2Qm27Pg") # GA2017

  for(key in keys){ # begin iteration over google sheets

  sheet <- as.data.frame(gs_read(gs_key(key), ws = "START_Sites", range = cell_cols(1:12), col_names=T, skip=1)) # import data from googlesheet

  # format data
  sheet <- sheet[is.na(sheet$CODE)==F,]   # remove empty lines
  colnames(sheet) <- c("code",  "producer_id", "year", "state", "last_name", "email", "phone", "address",
                       "county", "longitude-latitude", "notes",  "additional_contact") # rename colunmns



  # ----- Make sure data satisfy the foreign key constraint -----

  # list all codes in the codes table
  codes <- c(as.data.frame(dbGetQuery(con, "SELECT * FROM codes")))[[1]]

  # list all states in the states table
  states <- c(as.data.frame(dbGetQuery(con, "SELECT * FROM states")))[[1]]

  # list all producer ids in the states table
  ids <- c(as.data.frame(dbGetQuery(con, "SELECT * FROM producer_ids")))[[1]]

  ## codes
  if(NROW(sheet[(sheet$code %in% codes) == F,])>0){ # check if some 3-letter codes were not properly defined
      subset <- sheet[(sheet$code %in% codes) == F,] # select all lines with 3-letter codes not properly defined
      for(row in 1:NROW(subset)){ # begin iteration over the 3-letter codes that were not properly defined
         logwarn(paste(paste(subset[row,], collapse = ' - '),": 3-letter farm code was not properly defined", sep=""),  logger = "") # write warning onto log file
      } # end iteration over the 3-letter codes that were not properly defined
    sheet <- sheet[sheet$code %in% codes,]  # discard row
  } # end check on 3-letter codes

  ## states
  if(NROW(sheet[(sheet$state %in% states) == F,])>0){ # check if some state were not properly defined

    subset <- sheet[(sheet$state %in% states) == F,] # select all lines with states not properly defined
    for(row in 1:NROW(subset)){ # begin iteration over the 3-letter codes that were not properly defined
      logwarn(paste(paste(subset[row,], collapse = ' - '),": state was not properly defined",sep = ""),  logger = "") # write warning onto log file
    } # end iteration over the 3-letter codes that were not properly defined
    sheet$state[(sheet$state %in% states) == F] <- '[null]' # define state as null
  } # end check on states

  ## producer_ids
  if(NROW(sheet[(sheet$producer_id %in% ids) == F,])>0){ # check if some producer ids were not properly defined

    subset <- sheet[(sheet$producer_id %in% ids) == F,] # select all lines with producer ids not properly defined
    for(row in 1:NROW(subset)){ # begin iteration over the 3-letter codes that were not properly formatted
      logwarn(paste(paste(subset[row,], collapse = ' - '),": producer_ids was not properly defined", sep=""),  logger = "") # write warning onto log file
    } # end iteration over the 3-letter codes that were not properly formated
    sheet$state[(sheet$producer_id[row] %in% ids) == F] <- '[null]' # define producer id as null
  } # end check on states


  # ----- Complete Database -----

  # list all codes already in site_information in the database
  codes <- c(as.data.frame(dbGetQuery(con, "SELECT code FROM site_information")))
  if(length(codes) == 0) {codes <- list(0)} # if nothing in table set to 0


  for (obs in 1:NROW(sheet)) { # begin iteration over observations in spreadsheet

    if (is.na(sheet[obs,10]) == F){
      longitude <- as.numeric(unlist(strsplit(sheet[obs,10],","))[2])
      latitude <- as.numeric(unlist(strsplit(sheet[obs,10],","))[1])
    }
    if (is.na(sheet[obs,10]) == T){
      longitude <- 0
      latitude <- 0
    }

    if((sheet$code[obs] %in% codes[[1]])==F){ # if code is not already in database


      codes.temp <- data.frame(code = sheet$code[obs],  year = sheet$year[obs],
                               state = sheet$state[obs], county = sheet$county[obs],
                               longitude = longitude,  latitude = latitude,
                               notes = sheet$notes[obs], additional_contact = sheet$additional_contact[obs],
                               producer_id = sheet$producer_id[obs], stringsAsFactors = F)

      dbWriteTable(con, "site_information", value = codes.temp, append=T, row.names=F) # add observation into database
      loginfo(paste("ADDED:",paste(codes.temp, collapse = ' - ')), logger = "") # complete log file

      } # end if statement checking if code is already in database

    if(sheet$code[obs] %in% codes[[1]]){ # if code is already in database

      # extract information available for that producer in database
      site.info <- dbGetQuery(con, paste("SELECT * FROM site_information WHERE code ='",sheet$code[obs],"'", sep=""))

        data.equal <- T # variable defined to test if changes were made in the  google sheet

        codes.temp <- data.frame(code = sheet$code[obs],  year = sheet$year[obs],
                                 state = sheet$state[obs], county = sheet$county[obs],
                                 longitude = round(longitude, digits=4),  latitude = round(latitude, digits=4),
                                 notes = sheet$notes[obs], additional_contact = sheet$additional_contact[obs],
                                 producer_id = sheet$producer_id[obs], stringsAsFactors = F)


        for (col in 2:NCOL(site.info)){  # check column by columns if what is in google sheet matches what is in the DB
          if((is.na(site.info[,col]) == T & is.na(codes.temp[,col-1]) == T)==F){ # make sure both values are not NA
            if (identical(as.character(site.info[,col]), as.character(codes.temp[,col-1])) == F ){data.equal <- F
            } # if difference, set variable to False
          }}


        if(data.equal == F) { # if data entry are not equal, update DB

          if (is.na(codes.temp$year[1])==T) {codes.temp$year[1] <- '[null]'} # account for null data
          if (is.na(codes.temp$state[1])==T) {codes.temp$state[1] <- '[null]'} # account for null data
          if (is.na(codes.temp$county[1])==T) {codes.temp$county[1] <- '[null]'} # account for null data
          if (is.na(codes.temp$notes[1])==T) {codes.temp$notes[1] <- '[null]'} # account for null data
          if (is.na(codes.temp$additional_contact[1])==T) {codes.temp$additional_contact[1] <- '[null]'} # account for null data
          if (is.na(codes.temp$year[1])==T) {codes.temp$year[1] <- '[null]'} # account for null data


          update <- paste("UPDATE site_information SET year='", codes.temp$year[1],
                          "', state='", codes.temp$state[1],
                          "', county='", codes.temp$county[1],
                          "', longitude='", codes.temp$longitude[1],
                          "', latitude='", codes.temp$latitude[1],
                          "', notes='", codes.temp$notes[1],
                          "', additional_contact='", codes.temp$additional_contact[1],
                          "', producer_id='", codes.temp$producer_id[1],
                          "' WHERE code ='", codes.temp$code[1], "'", sep="") # define SQL query

          dbGetQuery(con, update) # update DB
          loginfo(paste("MODIFIED: OLD: ",paste(site.info, collapse = ' - ')), logger = "") # complete log file
          loginfo(paste("MODIFIED: NEW: ",paste(codes.temp, collapse = ' - ')), logger = "") # complete log file

        } # end if statement checking if the two entries are equal
    } # end if statement checking if producer is already in database
 } # end iteration over observations in spreadsheet

  } # end  iteration over google sheets

  # nullify NAs
  nullif <- "UPDATE producer_ids SET email =NULLIF(email, '[null]'), phone = NULLIF(phone, '[null]'), address = NULLIF(address,'[null]')"
  dbGetQuery(con, nullif)

  nullif <- "UPDATE site_information SET year =NULLIF(year, '[null]'),
  county =NULLIF(county, '[null]'), longitude =NULLIF(longitude, '0'),
  latitude =NULLIF(latitude, '0'), notes =NULLIF(notes, '[null]'),
  additional_contact =NULLIF(additional_contact, '[null]')"

  dbGetQuery(con, nullif)

  loginfo("Table: site_information", logger = "")
  loginfo(paste("Time end:", Sys.time()), logger="")


} # end function


