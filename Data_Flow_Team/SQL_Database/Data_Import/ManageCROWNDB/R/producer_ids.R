ImportProducerIds <- function(){ # begin function to import producer_ids

  # ----- Complete Log File -----

  loginfo("Table: producer_ids", logger = "")
  loginfo(paste("Time ini:", Sys.time()), logger="")

  # ----- Connect to postgresql database -----

  con <- ConnectToDB() # connect to postgresql database
  on.exit(dbDisconnect(con)) # on exit, close connection

  # ----- Create file to store all producers id present in google spreadsheets -----

  ids.list <- c()

  # ----- Import data from Google Spreadsheet -----

  # import data from google sheet
  keys <- c("1Az_8qAfpjVta9vXZFhr3YTsxSsLGHQmGTsPU2Qm27Pg",# GA2017
            "1O3lqSHNw_Q4PHLYKZ86vW3AxkZGD1u-OFMKV_cz4xL4", # NC2017
            "1-LZU9nkTZNvYGqxHx3Gis37vRrRM_ZOBYPNkBcEqKi0", # MD2017
            "1DXVi4MaEvZ_UbNu-pcT5skeb_4GfMCqS4cNkb494-OE",  # GA2018
            "1j4kLc9e0P_Z5gGrJVtMVatJ7m2GfjrK6cFDYZ___CeM", # NC2018
            "1R9KMVoGzr_62_0aOp9zn8JGi160OdRhpklzF2fnEPi8", # MD2018
            "1YjaHe8eVsdV0TV6tadF3KSgcylfjDHeduUHRE1-uN3s") # 2019

  for(key in keys){ # begin iteration over google sheets

  sheet <- as.data.frame(gs_read(gs_key(key), ws = "START_Sites", range = cell_cols(1:12), col_names=T, skip=1)) # import data from googlesheet

  # format data
  sheet <- sheet[is.na(sheet$Producer_ID)==F,]   # remove empty lines
  colnames(sheet) <- c("code",  "producer_id", "year", "state", "last_name", "email", "phone", "address",
                       "county", "longitude-latitude", "notes",  "additional_contact") # rename colunmns

  # format phone number
  sheet$phone <- gsub("-","",sheet$phone)
  sheet$phone <- gsub(" ","",sheet$phone)
  sheet$phone <- gsub("\\(","",sheet$phone)
  sheet$phone <- gsub(")","",sheet$phone)
  sheet$phone <- gsub(".","",sheet$phone)

  # add producer ids to sheet
  ids.list <- c(ids.list, sheet$producer_id)

  # ----- Complete Database -----

  for (obs in 1:NROW(sheet)) { # begin iteration over observations in spreadsheet

    # list all producer_ids already in the producer_ids table in database
    ids <- c(as.data.frame(dbGetQuery(con, "SELECT producer_id FROM producer_ids"))) # select all producer_ids existing in DB
    if(length(ids) == 0) {ids <- list(0)} # if nothing in table set to 0


    if((sheet$producer_id[obs] %in% ids[[1]])==F){ # if producer_id not already in database
      dbWriteTable(con, "producer_ids", value = sheet[obs,c(2,5:7)], append=T, row.names=F) # add observation into database
      loginfo(paste("ADDED:",paste(sheet[obs,c(2,5:7)], collapse = ' - ')), logger = "") # complete log file
    } # end if statement checking if producer_id is already in database

    if(sheet$producer_id[obs] %in% ids[[1]]){ # if producer_id is already in database

      # extract information available for that producer in database
      producer <- dbGetQuery(con, paste("SELECT * FROM producer_ids WHERE producer_id ='",sheet$producer_id[obs],"'", sep=""))

      if(identical(producer$last_name,sheet$last_name[obs])==F){ # if producer name is not the same, do nothing and output warning
        state <- substr(sheet$producer_id[obs], start=5, stop=6)
        logwarn(paste(state,": ",paste(sheet[obs,c(2,5:7)], collapse = ' - '),": same producer id was attributed to two farmers", sep=""),  logger = "")
      }

      if(identical(producer$last_name,sheet$last_name[obs])){  # if producer name is the same, continue

        data.equal <- T # variable defined to test if changes were made in the  google sheet
        temp <- sheet[,c(2,5:7)]

        for (col in 1:NCOL(producer)){  # check column by columns if what is in google sheet matches what is in the DB
          if((is.na(producer[,col]) == T & is.na(temp[obs,col]) == T)==F){ # make sure both values are not NA
            if (identical(as.character(producer[,col]), as.character(temp[obs,col])) == F ){data.equal <- F} # if difference, set variable to False
          }}


        if(data.equal == F) { # if data entry are not equal, update DB

          if (is.na(sheet$email[obs])==T) {sheet$email[obs] <- '[null]'} # account for null data
          if (is.na(sheet$phone[obs])==T) {sheet$phone[obs] <- '[null]'} # account for null data


          update <- paste("UPDATE producer_ids SET producer_id='", sheet$producer_id[obs],
                          "', last_name='", sheet$last_name[obs],
                          "', email='", sheet$email[obs],
                          "', phone='", sheet$phone[obs],
                          "' WHERE producer_id ='", sheet$producer_id[obs], "'", sep="") # define SQL query

          dbGetQuery(con, update) # update DB
          loginfo(paste("MODIFIED: OLD: ",paste(producer, collapse = ' - ')), logger = "") # complete log file
          loginfo(paste("MODIFIED: NEW: ",paste(sheet[obs,c(2,5:7)], collapse = ' - ')), logger = "") # complete log file

        } # end if statement checking if the two entries are equal
      } #end if statement checking if the same if was given to two producers
    } # end if statement checking if producer is already in database
  } # end iteration over observations in spreadsheet

  } # end iteration over google sheets

  # nullify NAs
  nullif <- "UPDATE producer_ids SET email =NULLIF(email, '[null]'), phone = NULLIF(phone, '[null]')"
  dbGetQuery(con, nullif)

  # ----- Delete producer ids which are not used anymore -----

  ids.list <- data.frame(ids = unique(ids.list))
  ids.db <- data.frame(dbGetQuery(con, "SELECT * FROM producer_ids")) # select all producer_ids existing in DB
  colnames(ids.db)[1] <- "ids"

  # select data to delete
  ids.db <- ids.db[(ids.db$ids %in% ids.list$ids) == F,]

  # delete data from database
  if(NROW(ids.db)>0){
  for(obs in 1:NROW(ids.db)){
    delete <- paste("DELETE FROM producer_ids WHERE producer_id = '", ids.db$ids[obs], "'", sep="")
    dbGetQuery(con, delete)
    loginfo(paste("DELETED:",paste(ids.db[obs,], collapse = ' - ')), logger = "") # complete log file
  }}

  loginfo("Table: producer_ids", logger = "")
  loginfo(paste("Time end:", Sys.time()), logger="")

} # end function
