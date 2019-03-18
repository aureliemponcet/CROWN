ImportSiteInfoGA18 <- function(){ # begin function to import producer_ids

  # ----- Complete Log File -----

  loginfo("Table: producers_id and site_information", logger = "")
  loginfo(paste("Time ini:", Sys.time()), logger="")

  # ----- Connect to postgresql database -----

  con <- ConnectToDB() # connect to postgresql database
  on.exit(dbDisconnect(con)) # on exit, close connection

  # ----- Import data from Google Spreadsheet -----

  # import data from google sheet
  keyga18 <- gs_key("1DXVi4MaEvZ_UbNu-pcT5skeb_4GfMCqS4cNkb494-OE") # define address of googlesheet
  sheet <- as.data.frame(gs_read(keyga18, ws = "START_Sites", range = cell_cols(1:12), col_names=T, skip=1)) # import data from googlesheet
  loginfo("Table: producers_id: GA - Connected to DB", logger = "") # complete log file

  # format data
  sheet <- sheet[is.na(sheet$Producer_ID)==F,]   # remove empty lines
  colnames(sheet) <- c("code",  "producer_id", "year", "state", "last_name", "email", "phone", "address",
                       "county", "longitude-latitude", "notes",  "additional_contact") # rename colunmns



  # ----- Make sure data satisfy the foreign key constraint -----

  # list all states in the states table
  states <- c(as.data.frame(dbGetQuery(con, "SELECT * FROM states")))



  # ----- Complete Database -----

  # list all producer_ids already in the producer_ids table in database
  ids <- c(as.data.frame(dbGetQuery(con, "SELECT producer_id FROM producer_ids"))) # select all producer_ids existing in DB
  if(length(ids) == 0) {ids <- list(0)} # if nothing in table set to 0

  # list all codes alread in site_information in the database
  codes <- c(as.data.frame(dbGetQuery(con, "SELECT code FROM site_information")))
  if(length(codes) == 0) {codes <- list(0)} # if nothing in table set to 0


  for (obs in 1:NROW(sheet)) { # begin iteration over observations in spreadsheet

    # producer_ids

    if((sheet$producer_id[obs] %in% ids[[1]])==F){ # if producer_id not already in database
      dbWriteTable(con, "producer_ids", value = sheet[obs,c(2,5:8)], append=T, row.names=F) # add observation into database
      loginfo(paste("ADDED:",paste(sheet[obs,c(2,5:8)], collapse = ' - ')), logger = "") # complete log file
    } # end if statement checking if producer_id is already in database

    if(sheet$producer_id[obs] %in% ids[[1]]){ # if producer_id is already in database

      # extract information available for that producer in database
      producer <- dbGetQuery(con, paste("SELECT * FROM producer_ids WHERE producer_id ='",sheet$producer_id[obs],"'", sep=""))

      if(identical(producer$last_name,sheet$last_name[obs])==F){ # if producer name is not the same, do nothing and output warning
        state <- substr(sheet$producer_id[obs], start=5, stop=6)
        logwarn(paste(state,": ",paste(sheet[obs,c(2,5:8)], collapse = ' - '),": same producer id was attributed to two farmers", sep=""),  logger = "")
      }

      if(identical(producer$last_name,sheet$last_name[obs])){  # if producer name is the same, continue

        data.equal <- T # variable defined to test if changes were made in the  google sheet
        temp <- sheet[,c(2,5:8)]

        for (col in 1:NCOL(producer)){  # check column by columns if what is in google sheet matches what is in the DB
          if((is.na(producer[,col]) == T & is.na(temp[obs,col]) == T)==F){ # make sure both values are not NA
            if (identical(producer[,col], temp[obs,col]) == F ){data.equal <- F} # if difference, set variable to False
          }}


        if(data.equal == F) { # if data entry are not equal, update DB

          if (is.na(sheet$email[obs])==T) {sheet$email[obs] <- '[null]'} # account for null data
          if (is.na(sheet$phone[obs])==T) {sheet$phone[obs] <- '[null]'} # account for null data
          if (is.na(sheet$address[obs])==T) {sheet$address[obs] <- '[null]'} # account for null data


          update <- paste("UPDATE producer_ids SET producer_id='", sheet$producer_id[obs],
                          "', last_name='", sheet$last_name[obs],
                          "', email='", sheet$email[obs],
                          "', phone='", sheet$phone[obs],
                          "', address='", sheet$address[obs],
                          "' WHERE producer_id ='", sheet$producer_id[obs], "'", sep="") # define SQL query

          dbGetQuery(con, update) # update DB
          loginfo(paste("MODIFIED: OLD: ",paste(producer, collapse = ' - ')), logger = "") # complete log file
          loginfo(paste("MODIFIED: NEW: ",paste(sheet[obs,c(2,5:8)], collapse = ' - ')), logger = "") # complete log file

        } # end if statement checking if the two entries are equal
      } #end if statement checking if the same if was given to two producers
    } # end if statement checking if producer is already in database
  } # end iteration over observations in spreadsheet


  for (obs in 1:NROW(sheet)) { # begin iteration over observations in spreadsheet

    # site_information

    if((sheet$code[obs] %in% codes[[1]])==F){ # if code is not already in database

      longitude <- as.numeric(unlist(strsplit(sheet[obs,10],","))[2])
      latitude <- as.numeric(unlist(strsplit(sheet[obs,10],","))[1])

      codes.temp <- data.frame(code = sheet$code[obs],  year = sheet$year[obs],
                               state = sheet$state[obs], county = sheet$county[obs],
                               longitude = longitude,  latitude = latitude,
                               notes = sheet$notes[obs], additional_contact = sheet$additional_contact[obs],
                               producer_id = sheet$producer_id[obs])

      dbWriteTable(con, "site_information", value = codes.temp, append=T, row.names=F) # add observation into database
      loginfo(paste("ADDED:",paste(codes.temp, collapse = ' - ')), logger = "") # complete log file

    } # end if statement checking if producer_id is already in database

    if(sheet$code[obs] %in% codes[[1]]){ # if code is already in database

      # extract information available for that producer in database
      site.info <- dbGetQuery(con, paste("SELECT * FROM site_information WHERE code ='",sheet$code[obs],"'", sep=""))

      data.equal <- T # variable defined to test if changes were made in the  google sheet

      if (is.na(sheet[obs,10]) == F){
        longitude <- as.numeric(unlist(strsplit(sheet[obs,10],","))[2])
        latitude <- as.numeric(unlist(strsplit(sheet[obs,10],","))[1])
      }
      if (is.na(sheet[obs,10]) == T){
        longitude <- 0
        latitude <- 0
      }

      codes.temp <- data.frame(code = sheet$code[obs],  year = sheet$year[obs],
                               state = sheet$state[obs], county = sheet$county[obs],
                               longitude = round(longitude, digits=4),  latitude = round(latitude, digits=4),
                               notes = sheet$notes[obs], additional_contact = sheet$additional_contact[obs],
                               producer_id = sheet$producer_id[obs])


      for (col in 2:NCOL(site.info)){  # check column by columns if what is in google sheet matches what is in the DB
        if((is.na(site.info[,col]) == T & is.na(codes.temp[,col-1]) == T)==F){ # make sure both values are not NA
          if (identical(as.character(site.info[,col]), as.character(codes.temp[,col-1])) == F ){data.equal <- F
          print(col)} # if difference, set variable to False
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

  # nullify NAs
  nullif <- "UPDATE producer_ids SET email =NULLIF(email, '[null]'), phone = NULLIF(phone, '[null]'), address = NULLIF(address,'[null]')"
  dbGetQuery(con, nullif)

  nullif <- "UPDATE site_information SET year =NULLIF(year, '[null]'),
  county =NULLIF(county, '[null]'), longitude =NULLIF(longitude, 0),
  latitude =NULLIF(latitude, 0), notes =NULLIF(notes, '[null]'),
  additional_contact =NULLIF(additional_contact, '[null]')"

  dbGetQuery(con, nullif)

  loginfo("Table: producers_ids and site_information", logger = "")
  loginfo(paste("Time end:", Sys.time()), logger="")


} # end function
