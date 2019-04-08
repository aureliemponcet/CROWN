ImportFarmHistory <- function(){ # begin function to import farm_history

  # ----- Complete Log File -----

  loginfo("Table: farm_history", logger = "")
  loginfo(paste("Time ini:", Sys.time()), logger="")

  # ----- Connect to postgresql database -----

  con <- ConnectToDB() # connect to postgresql database
  on.exit(dbDisconnect(con)) # on exit, close connection

  # ----- Create file to store all farm id present in the FieldManagement sheets -----

  hist.list <- c()


  # ----- Import data from Google Spreadsheet -----

  # import data from google sheet
  keys <- c("1Az_8qAfpjVta9vXZFhr3YTsxSsLGHQmGTsPU2Qm27Pg",# GA2017
  "1O3lqSHNw_Q4PHLYKZ86vW3AxkZGD1u-OFMKV_cz4xL4", # NC2017
  # "1-LZU9nkTZNvYGqxHx3Gis37vRrRM_ZOBYPNkBcEqKi0", # MD2017
  "1DXVi4MaEvZ_UbNu-pcT5skeb_4GfMCqS4cNkb494-OE",  # GA2018
  "1j4kLc9e0P_Z5gGrJVtMVatJ7m2GfjrK6cFDYZ___CeM", # NC2018
  # "1R9KMVoGzr_62_0aOp9zn8JGi160OdRhpklzF2fnEPi8", # MD2018
  "1YjaHe8eVsdV0TV6tadF3KSgcylfjDHeduUHRE1-uN3s") # 2019

  for(key in keys){ # begin iteration over google sheets

    sheet <- as.data.frame(gs_read(gs_key(key), ws = "FieldManagement", range = cell_cols(1:44), col_names=T, skip=1)) # import data from googlesheet

    # format data
    sheet <- sheet[is.na(sheet$CODE)==F,]   # remove empty lines
    sheet <- sheet[,c(1:4,17:44)]
    sheet <- sheet[,c(1,6:7,2,15,16,9,17,8,10,3,11,5,18,24,19,20:23,25:28,29:31,32)]
    colnames(sheet) <- c("code","previous_cash_crop", "next_cash_crop",
                         "cc_planting_date", "cc_termination_date", "cash_crop_planting_date", "kill_time",
                         "row_spacing", "subsoiling", "strip-till", "cc_planting_method", "cc_termination_method",
                         "cc_total_rate", "fall_sampling_date", "spring_sampling_date", "tot_n_previous_crop",
                         "post_harvest_fertility", "post_harvest_fertility_date", "post_harvest_fertility_source", "post_harvest_fertility_rate",
                         "at_pre_planting_fertilization", "at_pre_planting_fertilization_date","at_pre_planting_fertilization_method", "at_pre_planting_fertilization_rate",
                         "sidedress","sidedress_date","sidedress_rate","total_applied_n_rate")

    # convert dates to character
    sheet <- within(sheet, {cc_planting_date <- as.character(cc_planting_date);
    cc_termination_date <- as.character(cc_termination_date);
    cash_crop_planting_date <- as.character(cash_crop_planting_date)})

    # add farm ids to list
    hist.list <- c(hist.list, sheet$code)


    # ----- Format Data and Make Sure All Constraints are Satisfied -----


    #### Codes ####

    codes <- c(as.data.frame(dbGetQuery(con, "SELECT * FROM codes")))[[1]] # list all codes in the codes table

    if(NROW(sheet[(sheet$code %in% codes) == F,])>0){ # check if some 3-letter codes were not properly defined
      subset <- sheet[(sheet$code %in% codes) == F,] # select all lines with 3-letter codes not properly defined
      for(row in 1:NROW(subset)){ # begin iteration over the 3-letter codes that were not properly defined
        logwarn(paste(paste(subset[row,], collapse = ' - '),": 3-letter farm code was not properly defined", sep=""),  logger = "") # write warning onto log file
      } # end iteration over the 3-letter codes that were not properly defined
      sheet <- sheet[sheet$code %in% codes,]  # discard row
    } # end check on 3-letter codes


    #### Previous and Next Cash Crops ####

    cashcrop <- c(as.data.frame(dbGetQuery(con, "SELECT * FROM cash_crops")))[[1]] # list all codes in the codes table

    # previous cash crop
    if(NROW(sheet[(sheet$previous_cash_crop %in% cashcrop) == F & is.na(sheet$previous_cash_crop) == F,])>0){ # check if some cash crops were not properly defined
      subset <- sheet[(sheet$previous_cash_crop %in% cashcrop) == F,] # select all lines with cash crops not properly defined
      for(row in 1:NROW(subset)){ # begin iteration over the cash crops that were not properly defined
        state <- c(as.data.frame(dbGetQuery(con, paste("SELECT state FROM site_information WHERE code='",subset$code[row],"'", sep=""))))[[1]] # corresponding state
        logwarn(paste(state, ": ", paste(subset[row,], collapse = ' - '),": previous cash crop was not properly defined", sep=""),  logger = "") # write warning onto log file
      } # end iteration over the 3-letter codes that were not properly defined
      sheet <- sheet[sheet$previous_cash_crop %in% cashcrop,]  # discard row
    }

    # next cash crop
    if(NROW(sheet[(sheet$next_cash_crop %in% cashcrop) == F & is.na(sheet$next_cash_crop) == F,])>0){ # check if some cash crops were not properly defined
      subset <- sheet[(sheet$next_cash_crop %in% cashcrop) == F,] # select all lines with cash crops not properly defined
      for(row in 1:NROW(subset)){ # begin iteration over the cash crops that were not properly defined
        state <- c(as.data.frame(dbGetQuery(con, paste("SELECT state FROM site_information WHERE code='",subset$code[row],"'", sep=""))))[[1]] # corresponding state
        logwarn(paste(state, ": ", paste(subset[row,], collapse = ' - '),": next cash crop was not properly defined", sep=""),  logger = "") # write warning onto log file
      } # end iteration over the 3-letter codes that were not properly defined
      sheet <- sheet[sheet$next_cash_crop %in% cashcrop,]  # discard row
    }


    #### Dates ####

    IsDate <- function(mydate, date.format = "%y-%m-%d") {
      tryCatch(!is.na(as.Date(mydate, date.format)), error = function(err) {FALSE})
    }

    # Cover Crop Planting Date
    if(NROW(sheet[IsDate(as.Date(sheet$cc_planting_date)) == F & is.na(sheet$cc_planting_date) == F,])>0){
      subset <- sheet[IsDate(as.Date(sheet$cc_planting_date)) == F,]
      for(row in 1:NROW(subset)){ # begin iteration over rows
        state <- c(as.data.frame(dbGetQuery(con, paste("SELECT state FROM site_information WHERE code='",subset$code[row],"'", sep=""))))[[1]] # corresponding state
        logwarn(paste(paste(subset[row,], collapse = ' - '),": cover crop planting date was not properly defined", sep=""),  logger = "") # write warning onto log file
      } # end iteration over rows
      sheet$cc_planting_date[IsDate(as.Date(sheet$cc_planting_date)) == F] <- '[null]'
    }


    # Cover Crop Termination Date
    if(NROW(sheet[IsDate(as.Date(sheet$cc_termination_date)) == F & is.na(sheet$cc_termination_date) == F,])>0){
      subset <- sheet[IsDate(as.Date(sheet$cc_termination_date)) == F,]
      for(row in 1:NROW(subset)){ # begin iteration over rows
        state <- c(as.data.frame(dbGetQuery(con, paste("SELECT state FROM site_information WHERE code='",subset$code[row],"'", sep=""))))[[1]] # corresponding state
        logwarn(paste(paste(subset[row,], collapse = ' - '),": cover crop termination date was not properly defined", sep=""),  logger = "") # write warning onto log file
      } # end iteration over rows
      sheet$cc_termination_date[IsDate(as.Date(sheet$cc_planting_date)) == F] <- '[null]'
    }

    # Cash Crop Planting Date
    if(NROW(sheet[IsDate(as.Date(sheet$cash_crop_planting_date)) == F & is.na(sheet$cash_crop_planting_date) == F,])>0){
      subset <- sheet[IsDate(as.Date(sheet$cash_crop_planting_date)) == F,]
      for(row in 1:NROW(subset)){ # begin iteration over rows
        state <- c(as.data.frame(dbGetQuery(con, paste("SELECT state FROM site_information WHERE code='",subset$code[row],"'", sep=""))))[[1]] # corresponding state
        logwarn(paste(paste(subset[row,], collapse = ' - '),": cash crop planting date was not properly defined", sep=""),  logger = "") # write warning onto log file
      } # end iteration over rows
      sheet$cash_crop_planting_date[IsDate(as.Date(sheet$cc_planting_date)) == F] <- '[null]'
    }

    # Fall Sampling Date
    if(NROW(sheet[IsDate(as.Date(sheet$fall_sampling_date)) == F & is.na(sheet$fall_sampling_date) == F,])>0){
      subset <- sheet[IsDate(as.Date(sheet$fall_sampling_date)) == F,]
      for(row in 1:NROW(subset)){ # begin iteration over rows
        state <- c(as.data.frame(dbGetQuery(con, paste("SELECT state FROM site_information WHERE code='",subset$code[row],"'", sep=""))))[[1]] # corresponding state
        logwarn(paste(paste(subset[row,], collapse = ' - '),": fall sampling date was not properly defined", sep=""),  logger = "") # write warning onto log file
      } # end iteration over rows
      sheet$fall_sampling_date[IsDate(as.Date(sheet$fall_sampling_date)) == F] <- '[null]'
    }

    # Spring Sampling Date
    if(NROW(sheet[IsDate(as.Date(sheet$spring_sampling_date)) == F & is.na(sheet$spring_sampling_date) == F,])>0){
      subset <- sheet[IsDate(as.Date(sheet$spring_sampling_date)) == F,]
      for(row in 1:NROW(subset)){ # begin iteration over rows
        state <- c(as.data.frame(dbGetQuery(con, paste("SELECT state FROM site_information WHERE code='",subset$code[row],"'", sep=""))))[[1]] # corresponding state
        logwarn(paste(paste(subset[row,], collapse = ' - '),": spring sampling date was not properly defined", sep=""),  logger = "") # write warning onto log file
      } # end iteration over rows
      sheet$spring_sampling_date[IsDate(as.Date(sheet$spring_sampling_date)) == F] <- '[null]'
    }

    # Post-Harvest Fertility Date
    if(NROW(sheet[IsDate(as.Date(sheet$post_harvest_fertility_date)) == F & is.na(sheet$post_harvest_fertility_date) == F,])>0){
      subset <- sheet[IsDate(as.Date(sheet$post_harvest_fertility_date)) == F,]
      for(row in 1:NROW(subset)){ # begin iteration over rows
        state <- c(as.data.frame(dbGetQuery(con, paste("SELECT state FROM site_information WHERE code='",subset$code[row],"'", sep=""))))[[1]] # corresponding state
        logwarn(paste(paste(subset[row,], collapse = ' - '),": post-harvest fertility date was not properly defined", sep=""),  logger = "") # write warning onto log file
      } # end iteration over rows
      sheet$post_harvest_fertility_date[IsDate(as.Date(sheet$post_harvest_fertility_date)) == F] <- '[null]'
    }

    # At/Pre Planting Fertilization Date
    if(NROW(sheet[IsDate(as.Date(sheet$at_pre_planting_fertilization_date)) == F & is.na(sheet$at_pre_planting_fertilization_date) == F,])>0){
      subset <- sheet[IsDate(as.Date(sheet$at_pre_planting_fertilization_date)) == F,]
      for(row in 1:NROW(subset)){ # begin iteration over rows
        state <- c(as.data.frame(dbGetQuery(con, paste("SELECT state FROM site_information WHERE code='",subset$code[row],"'", sep=""))))[[1]] # corresponding state
        logwarn(paste(paste(subset[row,], collapse = ' - '),": at/pre planting fertilization date was not properly defined", sep=""),  logger = "") # write warning onto log file
      } # end iteration over rows
      sheet$at_pre_planting_fertilization_date[IsDate(as.Date(sheet$at_pre_planting_fertilization_date)) == F] <- '[null]'
    }

    # Sidedress Date
    if(NROW(sheet[IsDate(as.Date(sheet$sidedress_date)) == F & is.na(sheet$sidedress_date) == F,])>0){
      subset <- sheet[IsDate(as.Date(sheet$sidedress_date)) == F,]
      for(row in 1:NROW(subset)){ # begin iteration over rows
        state <- c(as.data.frame(dbGetQuery(con, paste("SELECT state FROM site_information WHERE code='",subset$code[row],"'", sep=""))))[[1]] # corresponding state
        logwarn(paste(paste(subset[row,], collapse = ' - '),": sidedress date was not properly defined", sep=""),  logger = "") # write warning onto log file
      } # end iteration over rows
      sheet$sidedress_date[IsDate(as.Date(sheet$sidedress_date)) == F] <- '[null]'
    }


    #### Booleans ####

    # kill time
    sheet$kill_time[sheet$kill_time == "Before"] <- FALSE
    sheet$kill_time[sheet$kill_time == "After"] <- TRUE

    # subsoiling
    sheet$subsoiling[sheet$subsoiling == "No"] <- FALSE
    sheet$subsoiling[sheet$subsoiling == "Yes"] <- TRUE

    # strip-till
    sheet$`strip-till`[sheet$`strip-till` == "No"] <- FALSE
    sheet$`strip-till`[sheet$`strip-till` == "Yes"] <- TRUE

    # post-harvest fertility
    sheet$post_harvest_fertility[sheet$post_harvest_fertility == "No"] <- FALSE
    sheet$post_harvest_fertility[sheet$post_harvest_fertility == "Yes"] <- TRUE

    # at/pre planting fertility
    sheet$at_pre_planting_fertilization[sheet$at_pre_planting_fertilization == "No"] <- FALSE
    sheet$at_pre_planting_fertilization[sheet$at_pre_planting_fertilization == "Yes"] <- TRUE

    # sidedress
    sheet$sidedress[sheet$sidedress == "No"] <- FALSE
    sheet$sidedress[sheet$sidedress == "Yes"] <- TRUE



    #### Cover Crop Planting Methods ####

    planting <- c(as.data.frame(dbGetQuery(con, "SELECT * FROM cc_planting_methods")))[[1]] # list all codes in the codes table

    # previous cash crop
    if(NROW(sheet[(sheet$cc_planting_method %in% planting) == F & is.na(sheet$cc_planting_method) == F,])>0){ # check if some cash crops were not properly defined
      subset <- sheet[(sheet$cc_planting_method %in% planting) == F,] # select all lines with cash crops not properly defined
      for(row in 1:NROW(subset)){ # begin iteration over the cash crops that were not properly defined
        state <- c(as.data.frame(dbGetQuery(con, paste("SELECT state FROM site_information WHERE code='",subset$code[row],"'", sep=""))))[[1]] # corresponding state
        logwarn(paste(state, ": ", paste(subset[row,], collapse = ' - '),": cover crop planting method was not properly defined", sep=""),  logger = "") # write warning onto log file
      } # end iteration over the 3-letter codes that were not properly defined
      sheet <- sheet[sheet$cc_planting_method  %in% planting,]  # discard row
    }


    #### Cover Crop Termination Methods ####

    termination <- c(as.data.frame(dbGetQuery(con, "SELECT * FROM cc_termination_methods")))[[1]] # list all codes in the codes table

    # previous cash crop
    if(NROW(sheet[(sheet$cc_termination_method %in% termination) == F & is.na(sheet$cc_termination_method) == F,])>0){ # check if some cash crops were not properly defined
      subset <- sheet[(sheet$cc_termination_method %in% termination) == F,] # select all lines with cash crops not properly defined
      for(row in 1:NROW(subset)){ # begin iteration over the cash crops that were not properly defined
        state <- c(as.data.frame(dbGetQuery(con, paste("SELECT state FROM site_information WHERE code='",subset$code[row],"'", sep=""))))[[1]] # corresponding state
        logwarn(paste(state, ": ", paste(subset[row,], collapse = ' - '),": cover crop termination method was not properly defined", sep=""),  logger = "") # write warning onto log file
      } # end iteration over the 3-letter codes that were not properly defined
      sheet <- sheet[sheet$cc_termination_method  %in% termination,]  # discard row
    }


    # ----- Complete Database -----

    # list all codes already in site_information in the database
    codes <- c(as.data.frame(dbGetQuery(con, "SELECT code FROM farm_history")))
    if(length(codes) == 0) {codes <- list(0)} # if nothing in table set to 0


    for (obs in 1:NROW(sheet)) { # begin iteration over observations in spreadsheet

      if((sheet$code[obs] %in% codes[[1]])==F){ # if code is not already in database

        codes.temp <- data.frame(code = sheet$code[obs],
                                 previous_cash_crop = sheet$previous_cash_crop[obs],
                                 next_cash_crop = sheet$next_cash_crop[obs],
                                 subsoiling = sheet$subsoiling[obs],
                                 strip_till = sheet$`strip-till`[obs],
                                 cc_planting_method = sheet$cc_planting_method[obs],
                                 cc_termination_method = sheet$cc_termination_method[obs],
                                 fall_sampling_date = sheet$fall_sampling_date[obs],
                                 spring_sampling_date = sheet$spring_sampling_date[obs],
                                 post_harvest_fertility_date = sheet$post_harvest_fertility_date[obs],
                                 post_harvest_fertility_source = sheet$post_harvest_fertility_source[obs],
                                 at_pre_planting_fertilization_date = sheet$at_pre_planting_fertilization_date[obs],
                                 at_pre_planting_fertilization_method = sheet$at_pre_planting_fertilization_method[obs],
                                 sidedress_date = sheet$sidedress_date[obs],
                                 cc_planting_date = sheet$cc_planting_date[obs],
                                 cc_termination_date = sheet$cc_termination_date[obs],
                                 cash_crop_planting_date = sheet$cash_crop_planting_date[obs],
                                 kill_time = sheet$kill_time[obs],
                                 cc_total_rate = sheet$cc_total_rate[obs],
                                 post_harvest_fertility_rate = sheet$post_harvest_fertility_rate[obs],
                                 at_pre_planting_fertilization_rate = sheet$at_pre_planting_fertilization_rate[obs],
                                 sidedress_rate = sheet$sidedress_rate[obs],
                                 row_spacing = sheet$row_spacing[obs],
                                 post_harvest_fertility = sheet$post_harvest_fertility[obs],
                                 at_pre_planting_fertilization = sheet$at_pre_planting_fertilization[obs],
                                 sidedress = sheet$sidedress[obs],
                                 total_n_previous_crop = sheet$tot_n_previous_crop[obs],
                                 total_applied_n_rate = sheet$tot_n_previous_crop[obs])


        dbWriteTable(con, "farm_history", value = codes.temp, append=T, row.names=F) # add observation into database
        loginfo(paste("ADDED:",paste(codes.temp, collapse = ' - ')), logger = "") # complete log file

      } # end if statement checking if code is already in database

      if(sheet$code[obs] %in% codes[[1]]){ # if code is already in database

        # extract information available for that producer in database
        farm.hist <- dbGetQuery(con, paste("SELECT * FROM farm_history WHERE code ='",sheet$code[obs],"'", sep=""))
        farm.hist <- farm.hist[,-15] # remove cid column

        data.equal <- T # variable defined to test if changes were made in the  google sheet

        codes.temp <- data.frame(code = sheet$code[obs],
                                 previous_cash_crop = sheet$previous_cash_crop[obs],
                                 next_cash_crop = sheet$next_cash_crop[obs],
                                 subsoiling = sheet$subsoiling[obs],
                                 strip_till = sheet$`strip-till`[obs],
                                 cc_planting_method = sheet$cc_planting_method[obs],
                                 cc_termination_method = sheet$cc_termination_method[obs],
                                 fall_sampling_date = sheet$fall_sampling_date[obs],
                                 spring_sampling_date = sheet$spring_sampling_date[obs],
                                 post_harvest_fertility_date = sheet$post_harvest_fertility_date[obs],
                                 post_harvest_fertility_source = sheet$post_harvest_fertility_source[obs],
                                 at_pre_planting_fertilization_date = sheet$at_pre_planting_fertilization_date[obs],
                                 at_pre_planting_fertilization_method = sheet$at_pre_planting_fertilization_method[obs],
                                 sidedress_date = sheet$sidedress_date[obs],
                                 kill_time = sheet$kill_time[obs],
                                 cc_planting_date = sheet$cc_planting_date[obs],
                                 cc_termination_date = sheet$cc_termination_date[obs],
                                 cash_crop_planting_date = sheet$cash_crop_planting_date[obs],
                                 cc_total_rate = sheet$cc_total_rate[obs],
                                 post_harvest_fertility_rate = sheet$post_harvest_fertility_rate[obs],
                                 at_pre_planting_fertilization_rate = sheet$at_pre_planting_fertilization_rate[obs],
                                 sidedress_rate = sheet$sidedress_rate[obs],
                                 row_spacing = sheet$row_spacing[obs],
                                 post_harvest_fertility = sheet$post_harvest_fertility[obs],
                                 at_pre_planting_fertilization = sheet$at_pre_planting_fertilization[obs],
                                 sidedress = sheet$sidedress[obs],
                                 total_n_previous_crop = sheet$tot_n_previous_crop[obs],
                                 total_applied_n_rate = sheet$tot_n_previous_crop[obs],
                                 stringsAsFactors = F)



        for (col in 1:NCOL(farm.hist)){  # check column by columns if what is in google sheet matches what is in the DB
          if((is.na(farm.hist[,col]) == T & is.na(codes.temp[,col]) == T)==F){ # make sure both values are not NA
            if (identical(as.character(farm.hist[,col]), as.character(codes.temp[,col])) == F ){data.equal <- F} # if difference, set variable to False
          }}


        if(data.equal == F) { # if data entry are not equal, update DB

          if (is.na(codes.temp$previous_cash_crop[1])==T) {codes.temp$previous_cash_crop[1] <- '[null]'} # account for null data
          if (is.na(codes.temp$next_cash_crop[1])==T) {codes.temp$next_cash_crop[1] <- '[null]'} # account for null data
          if (is.na(codes.temp$cc_planting_method[1])==T) {codes.temp$cc_planting_method[1] <- '[null]'} # account for null data
          if (is.na(codes.temp$cc_termination_method[1])==T) {codes.temp$cc_termination_method[1] <- '[null]'} # account for null data
          if (is.na(codes.temp$post_harvest_fertility_source[1])==T) {codes.temp$post_harvest_fertility_source[1] <- '[null]'} # account for null data
          if (is.na(codes.temp$at_pre_planting_fertilization_method[1])==T) {codes.temp$at_pre_planting_fertilization_method[1] <- '[null]'} # account for null data
          if (is.na(codes.temp$cc_total_rate[1])==T) {codes.temp$cc_total_rate[1] <- '[null]'} # account for null data
          if (is.na(codes.temp$post_harvest_fertility_rate[1])==T) {codes.temp$post_harvest_fertility_rate[1] <- '[null]'} # account for null data
          if (is.na(codes.temp$at_pre_planting_fertilization_rate[1])==T) {codes.temp$at_pre_planting_fertilization_rate[1] <- '[null]'} # account for null data
          if (is.na(codes.temp$sidedress_rate[1])==T) {codes.temp$sidedress_rate[1] <- '[null]'} # account for null data
          if (is.na(codes.temp$row_spacing[1])==T) {codes.temp$row_spacing[1] <- '0'} # account for null data



          if (is.na(codes.temp$subsoiling[1])==T) {
            update <- paste("UPDATE farm_history SET subsoiling= NULL WHERE code ='", codes.temp$code[1], "'", sep="") # define SQL query
            dbGetQuery(con, update) # update DB
          } else {
            update <- paste("UPDATE farm_history SET subsoiling='", codes.temp$subsoiling[1],"' WHERE code ='", codes.temp$code[1], "'", sep="") # define SQL query
            dbGetQuery(con, update) # update DB
          } # account for null data


          if (is.na(codes.temp$strip_till[1])==T) {
            update <- paste("UPDATE farm_history SET strip_till= NULL WHERE code ='", codes.temp$code[1], "'", sep="") # define SQL query
            dbGetQuery(con, update) # update DB
          } else {
            update <- paste("UPDATE farm_history SET strip_till='", codes.temp$strip_till[1],"' WHERE code ='", codes.temp$code[1], "'", sep="") # define SQL query
            dbGetQuery(con, update) # update DB
          } # account for null data


          if (is.na(codes.temp$fall_sampling_date[1])==T) {
            update <- paste("UPDATE farm_history SET fall_sampling_date= NULL WHERE code ='", codes.temp$code[1], "'", sep="") # define SQL query
            dbGetQuery(con, update) # update DB
          } else {
            update <- paste("UPDATE farm_history SET fall_sampling_date='", codes.temp$fall_sampling_date[1],"' WHERE code ='", codes.temp$code[1], "'", sep="") # define SQL query
            dbGetQuery(con, update) # update DB
          } # account for null data


          if (is.na(codes.temp$spring_sampling_date[1])==T) {
            update <- paste("UPDATE farm_history SET spring_sampling_date= NULL WHERE code ='", codes.temp$code[1], "'", sep="") # define SQL query
            dbGetQuery(con, update) # update DB
          } else {
            update <- paste("UPDATE farm_history SET spring_sampling_date='", codes.temp$spring_sampling_date[1],"' WHERE code ='", codes.temp$code[1], "'", sep="") # define SQL query
            dbGetQuery(con, update) # update DB
          } # account for null data


          if (is.na(codes.temp$post_harvest_fertility_date[1])==T) {
            update <- paste("UPDATE farm_history SET post_harvest_fertility_date= NULL WHERE code ='", codes.temp$code[1], "'", sep="") # define SQL query
            dbGetQuery(con, update) # update DB
          } else {
            update <- paste("UPDATE farm_history SET post_harvest_fertility_date='", codes.temp$post_harvest_fertility_date[1],"' WHERE code ='", codes.temp$code[1], "'", sep="") # define SQL query
            dbGetQuery(con, update) # update DB
          } # account for null data


          if (is.na(codes.temp$at_pre_planting_fertilization_date[1])==T) {
            update <- paste("UPDATE farm_history SET at_pre_planting_fertilization_date= NULL WHERE code ='", codes.temp$code[1], "'", sep="") # define SQL query
            dbGetQuery(con, update) # update DB
          } else {
            update <- paste("UPDATE farm_history SET at_pre_planting_fertilization_date='", codes.temp$at_pre_planting_fertilization_date[1],"' WHERE code ='", codes.temp$code[1], "'", sep="") # define SQL query
            dbGetQuery(con, update) # update DB
          } # account for null data


          if (is.na(codes.temp$sidedress_date[1])==T) {
            update <- paste("UPDATE farm_history SET sidedress_date= NULL WHERE code ='", codes.temp$code[1], "'", sep="") # define SQL query
            dbGetQuery(con, update) # update DB
          } else {
            update <- paste("UPDATE farm_history SET sidedress_date='", codes.temp$sidedress_date[1],"' WHERE code ='", codes.temp$code[1], "'", sep="") # define SQL query
            dbGetQuery(con, update) # update DB
          } # account for null data

          if (is.na(codes.temp$kill_time[1])==T) {
            update <- paste("UPDATE farm_history SET kill_time= NULL WHERE code ='", codes.temp$code[1], "'", sep="") # define SQL query
            dbGetQuery(con, update) # update DB
          } else {
            update <- paste("UPDATE farm_history SET kill_time='", codes.temp$kill_time[1],"' WHERE code ='", codes.temp$code[1], "'", sep="") # define SQL query
            dbGetQuery(con, update) # update DB
          } # account for null data

          if (is.na(codes.temp$cc_planting_date[1])==T) {
            update <- paste("UPDATE farm_history SET cc_planting_date= NULL WHERE code ='", codes.temp$code[1], "'", sep="") # define SQL query
            dbGetQuery(con, update) # update DB
          } else {
            update <- paste("UPDATE farm_history SET cc_planting_date='", codes.temp$cc_planting_date[1],"' WHERE code ='", codes.temp$code[1], "'", sep="") # define SQL query
            dbGetQuery(con, update) # update DB
          } # account for null data

          if (is.na(codes.temp$cc_termination_date[1])==T) {
            update <- paste("UPDATE farm_history SET cc_termination_date= NULL WHERE code ='", codes.temp$code[1], "'", sep="") # define SQL query
            dbGetQuery(con, update) # update DB
          } else {
            update <- paste("UPDATE farm_history SET cc_termination_date='", codes.temp$cc_termination_date[1],"' WHERE code ='", codes.temp$code[1], "'", sep="") # define SQL query
            dbGetQuery(con, update) # update DB
          } # account for null data

          if (is.na(codes.temp$cash_crop_planting_date[1])==T) {
            update <- paste("UPDATE farm_history SET cash_crop_planting_date= NULL WHERE code ='", codes.temp$code[1], "'", sep="") # define SQL query
            dbGetQuery(con, update) # update DB
          } else {
            update <- paste("UPDATE farm_history SET cash_crop_planting_date='", codes.temp$cash_crop_planting_date[1],"' WHERE code ='", codes.temp$code[1], "'", sep="") # define SQL query
            dbGetQuery(con, update) # update DB
          } # account for null data


          if (is.na(codes.temp$post_harvest_fertility[1])==T) {
            update <- paste("UPDATE farm_history SET post_harvest_fertility= NULL WHERE code ='", codes.temp$code[1], "'", sep="") # define SQL query
            dbGetQuery(con, update) # update DB
          } else {
            update <- paste("UPDATE farm_history SET post_harvest_fertility='", codes.temp$post_harvest_fertility[1],"' WHERE code ='", codes.temp$code[1], "'", sep="") # define SQL query
            dbGetQuery(con, update) # update DB
          } # account for null data


          if (is.na(codes.temp$at_pre_planting_fertilization[1])==T) {
            update <- paste("UPDATE farm_history SET at_pre_planting_fertilization= NULL WHERE code ='", codes.temp$code[1], "'", sep="") # define SQL query
            dbGetQuery(con, update) # update DB
          } else {
            update <- paste("UPDATE farm_history SET at_pre_planting_fertilization='", codes.temp$at_pre_planting_fertilization[1],"' WHERE code ='", codes.temp$code[1], "'", sep="") # define SQL query
            dbGetQuery(con, update) # update DB
          } # account for null data


          if (is.na(codes.temp$sidedress[1])==T) {
            update <- paste("UPDATE farm_history SET sidedress= NULL WHERE code ='", codes.temp$code[1], "'", sep="") # define SQL query
            dbGetQuery(con, update) # update DB
          } else {
            update <- paste("UPDATE farm_history SET sidedress='", codes.temp$sidedress[1],"' WHERE code ='", codes.temp$code[1], "'", sep="") # define SQL query
            dbGetQuery(con, update) # update DB
          } # account for null data


          if (is.na(codes.temp$total_n_previous_crop[1])==T) {
            update <- paste("UPDATE farm_history SET total_n_previous_crop= NULL WHERE code ='", codes.temp$code[1], "'", sep="") # define SQL query
            dbGetQuery(con, update) # update DB
          } else {
            update <- paste("UPDATE farm_history SET total_n_previous_crop='", codes.temp$total_n_previous_crop[1],"' WHERE code ='", codes.temp$code[1], "'", sep="") # define SQL query
            dbGetQuery(con, update) # update DB
          } # account for null data



          if (is.na(codes.temp$total_n_previous_crop[1])==T) {
            update <- paste("UPDATE farm_history SET total_applied_n_rate= NULL WHERE code ='", codes.temp$code[1], "'", sep="") # define SQL query
            dbGetQuery(con, update) # update DB
          } else {
            update <- paste("UPDATE farm_history SET total_applied_n_rate='", codes.temp$total_applied_n_rate[1],"' WHERE code ='", codes.temp$code[1], "'", sep="") # define SQL query
            dbGetQuery(con, update) # update DB
          } # account for null data



          update <- paste("UPDATE farm_history SET previous_cash_crop='", codes.temp$previous_cash_crop[1],
                          "', next_cash_crop='", codes.temp$next_cash_crop[1],
                          "', cc_planting_method='", codes.temp$cc_planting_method[1],
                          "', cc_termination_method='", codes.temp$cc_termination_method[1],
                          "', post_harvest_fertility_source='", codes.temp$post_harvest_fertility_source[1],
                          "', at_pre_planting_fertilization_method='", codes.temp$at_pre_planting_fertilization_method[1],
                          "', cc_total_rate='", codes.temp$cc_total_rate[1],
                          "', post_harvest_fertility_rate='", codes.temp$post_harvest_fertility_rate[1],
                          "', at_pre_planting_fertilization_rate='", codes.temp$at_pre_planting_fertilization_rate[1],
                          "', sidedress_rate='", codes.temp$sidedress_rate[1],
                          "', row_spacing='", codes.temp$row_spacing[1],
                           "' WHERE code ='", codes.temp$code[1], "'", sep="") # define SQL query

          dbGetQuery(con, update) # update DB
          loginfo(paste("MODIFIED: OLD: ",paste(farm.hist, collapse = ' - ')), logger = "") # complete log file
          loginfo(paste("MODIFIED: NEW: ",paste(farm.hist.temp, collapse = ' - ')), logger = "") # complete log file




        } # end if statement checking if the two entries are equal
      } # end if statement checking if producer is already in database
    } # end iteration over observations in spreadsheet
  } # end iteration over google sheets

  nullif <- "UPDATE farm_history SET previous_cash_crop =NULLIF(previous_cash_crop, '[null]'),
            next_cash_crop = NULLIF(next_cash_crop, '[null]'),
            cc_planting_method = NULLIF(cc_planting_method, '[null]'),
            cc_termination_method = NULLIF(cc_termination_method, '[null]'),
            post_harvest_fertility_source = NULLIF(post_harvest_fertility_source, '[null]'),
            at_pre_planting_fertilization_method = NULLIF(at_pre_planting_fertilization_method, '[null]'),
            post_harvest_fertility_rate = NULLIF(post_harvest_fertility_rate, '[null]'),
            at_pre_planting_fertilization_rate = NULLIF(at_pre_planting_fertilization_rate, '[null]'),
            sidedress_rate = NULLIF(sidedress_rate, '[null]'),
            row_spacing = NULLIF(row_spacing, '0')"

  dbGetQuery(con, nullif)


  # ----- Delete 3-letter codes which are not used anymore -----

  farms.list <- data.frame(code = unique(hist.list))
  farms.db <- data.frame(dbGetQuery(con, "SELECT * FROM farm_history")) # select all producer_ids existing in DB

  # select data to delete
  farms.db <- farms.db[(farms.db$code %in% farms.list$code) == F,]

  # delete data from database
  if(NROW(farms.db)>0){
    for(obs in 1:NROW(farms.db)){
      delete <- paste("DELETE FROM farm_history WHERE code = '", farms.db$code[obs], "'", sep="")
      dbGetQuery(con, delete)
      loginfo(paste("DELETED:",paste(farms.db[obs,], collapse = ' - ')), logger = "") # complete log file
    }}

  loginfo("Table: farm_history", logger = "")
  loginfo(paste("Time end:", Sys.time()), logger="")


} # end functionn to import farm_history
