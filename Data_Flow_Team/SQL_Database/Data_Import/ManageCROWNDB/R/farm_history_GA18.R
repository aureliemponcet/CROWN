ImportFarmHistoryGA18 <- function(){ # begin function to import farm_history

  # ----- Complete Log File -----

  loginfo("Table: farm_history", logger = "")
  loginfo(paste("Time ini:", Sys.time()), logger="")

  # ----- Connect to postgresql database -----

  con <- ConnectToDB() # connect to postgresql database
  on.exit(dbDisconnect(con)) # on exit, close connection

  # ----- Import data from Google Spreadsheet -----

  # import data from google sheet
  keyga18 <- gs_key("1DXVi4MaEvZ_UbNu-pcT5skeb_4GfMCqS4cNkb494-OE") # define address of googlesheet
  sheet <- as.data.frame(gs_read(keyga18, ws = "FieldManagement", range = cell_cols(1:44), col_names=T, skip=1)) # import data from googlesheet
  loginfo("Table: farm_history: GA - Connected to DB", logger = "") # complete log file

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


  # ----- Format Data and Make Sure All Constraints are Satisfied -----

  # convert dates to character
  sheet <- within(sheet, {cc_planting_date <- as.character(cc_planting_date);
                          cc_termination_date <- as.character(cc_termination_date);
                          cash_crop_planting_date <- as.character(cash_crop_planting_date)})

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
  if(NROW(sheet[(sheet$previous_cash_crop %in% cashcrop) == F,])>0){ # check if some cash crops were not properly defined
    subset <- sheet[(sheet$previous_cash_crop %in% cashcrop) == F,] # select all lines with cash crops not properly defined
    for(row in 1:NROW(subset)){ # begin iteration over the cash crops that were not properly defined
      state <- c(as.data.frame(dbGetQuery(con, paste("SELECT state FROM site_information WHERE code='",subset$code[row],"'", sep=""))))[[1]] # corresponding state
      logwarn(paste(state, ": ", paste(subset[row,], collapse = ' - '),": previous cash crop was not properly defined", sep=""),  logger = "") # write warning onto log file
    } # end iteration over the 3-letter codes that were not properly defined
    sheet$previous_cash_crop[(sheet$previous_cash_crop %in% cashcrop) == F] <- '[null]' # define state as null
   }

  # next cash crop
  if(NROW(sheet[(sheet$next_cash_crop %in% cashcrop) == F,])>0){ # check if some cash crops were not properly defined
    subset <- sheet[(sheet$next_cash_crop %in% cashcrop) == F,] # select all lines with cash crops not properly defined
    for(row in 1:NROW(subset)){ # begin iteration over the cash crops that were not properly defined
      state <- c(as.data.frame(dbGetQuery(con, paste("SELECT state FROM site_information WHERE code='",subset$code[row],"'", sep=""))))[[1]] # corresponding state
      logwarn(paste(state, ": ", paste(subset[row,], collapse = ' - '),": next cash crop was not properly defined", sep=""),  logger = "") # write warning onto log file
    } # end iteration over the 3-letter codes that were not properly defined
    sheet$next_cash_crop[(sheet$next_cash_crop %in% cashcrop) == F] <- '[null]' # define state as null
  }

  #### Dates ####

  IsDate <- function(mydate, date.format = "%y-%m-%d") {
    tryCatch(!is.na(as.Date(mydate, date.format)), error = function(err) {FALSE})
  }

  # Cover Crop Planting Date
  subset <- sheet[IsDate(as.Date(sheet$cc_planting_date)) == F,]
  for(row in 1:NROW(subset)){ # begin iteration over rows
      state <- c(as.data.frame(dbGetQuery(con, paste("SELECT state FROM site_information WHERE code='",subset$code[row],"'", sep=""))))[[1]] # corresponding state
      logwarn(paste(paste(subset[row,], collapse = ' - '),": cover crop planting date was not properly defined", sep=""),  logger = "") # write warning onto log file
  } # end iteration over rows
  sheet$cc_planting_date[IsDate(as.Date(sheet$cc_planting_date)) == F] <- '[null]'

  # Cover Crop Termination Date
  subset <- sheet[IsDate(as.Date(sheet$cc_termination_date)) == F,]
  for(row in 1:NROW(subset)){ # begin iteration over rows
    state <- c(as.data.frame(dbGetQuery(con, paste("SELECT state FROM site_information WHERE code='",subset$code[row],"'", sep=""))))[[1]] # corresponding state
    logwarn(paste(paste(subset[row,], collapse = ' - '),": cover crop planting date was not properly defined", sep=""),  logger = "") # write warning onto log file
  } # end iteration over rows
  sheet$cc_planting_date[IsDate(as.Date(sheet$cc_planting_date)) == F] <- '[null]'













 } # end functionn to import farm_history
