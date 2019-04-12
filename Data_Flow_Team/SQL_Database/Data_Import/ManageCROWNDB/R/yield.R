ImportYield <- function(){ # begin function to import yield

  # ----- Complete Log File -----

  loginfo("Table: yield", logger = "")
  loginfo(paste("Time ini:", Sys.time()), logger="")

  # ----- Connect to postgresql database -----

  con <- ConnectToDB() # connect to postgresql database
  on.exit(dbDisconnect(con)) # on exit, close connection

  # ----- Create file to store all farm id present in the FieldManagement sheets -----

  yield.list <- data.frame(code=character(), treatment=character(), subplot = character(), row = character(), stringsAsFactors = F)


  # ----- Import data from Google Spreadsheet -----

  # import data from google sheet
  keys <- c("1Az_8qAfpjVta9vXZFhr3YTsxSsLGHQmGTsPU2Qm27Pg",# GA2017
            "1O3lqSHNw_Q4PHLYKZ86vW3AxkZGD1u-OFMKV_cz4xL4", # NC2017
            "1-LZU9nkTZNvYGqxHx3Gis37vRrRM_ZOBYPNkBcEqKi0", # MD2017
            "1DXVi4MaEvZ_UbNu-pcT5skeb_4GfMCqS4cNkb494-OE")#,  # GA2018
            # "1j4kLc9e0P_Z5gGrJVtMVatJ7m2GfjrK6cFDYZ___CeM", # NC2018
            # "1R9KMVoGzr_62_0aOp9zn8JGi160OdRhpklzF2fnEPi8", # MD2018
            # "1YjaHe8eVsdV0TV6tadF3KSgcylfjDHeduUHRE1-uN3s") # 2019


  for(key in keys){ # begin iteration over google sheets

    sheet1 <- as.data.frame(gs_read(gs_key(key), ws = "Yield", range = cell_cols(1:9), col_names=F, skip=1)) # import data from googlesheet
    while(NCOL(sheet1)<9){sheet1[,ncol(sheet1)+1] <- NA}
    colnames(sheet1) <- c("barcode", "row_spacing", "harvest_wt", "moisture_1", "moisture_2", "percent_lint", "grain_test_wt1", "grain_test_wt2", "notes")

    sheet2 <- as.data.frame(gs_read(gs_key(key), ws = "Stand Counts", range = cell_cols(1:2), col_names=F, skip=1)) # import data from googlesheet
    colnames(sheet2) <- c("barcode", "stand_count")

    # merge sheet1 and sheet2
    sheet <- merge(sheet1, sheet2, by="barcode")
    rm(sheet1); rm(sheet2)

    # format data
    sheet$barcode <- gsub(" ","",sheet$barcode) # remove spaces from barcodes
    sheet$code <- substr(sheet$barcode, start = 2, stop = 4)
    sheet$treatment <-  substr(sheet$barcode, start = 5, stop = 5)
    sheet$subplot <-  substr(sheet$barcode, start = 6, stop = 6)
    sheet$row <-  substr(sheet$barcode, start = 7, stop = 8)

    sheet <- within(sheet, {barcode <- as.character(barcode); row_spacing <- as.numeric(row_spacing);
    harvest_wt <- as.numeric(harvest_wt); moisture_1 <- as.numeric(moisture_1); moisture_2 <- as.numeric(moisture_2);
    percent_lint <- as.numeric(percent_lint); grain_test_wt1 <- as.numeric(grain_test_wt1); grain_test_wt2 <- as.numeric(grain_test_wt2);
    notes <- as.character(notes);  stand_count <- as.numeric(stand_count)})

    # add farm ids to list
    yield.list <- rbind(yield.list, sheet[,11:14])


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

    #### Treatment ####

    trts <- c(as.data.frame(dbGetQuery(con, "SELECT * FROM treatments")))[[1]] # list all codes in the codes table

    if(NROW(sheet[(sheet$treatment %in% trts) == F,])>0){ # check if some 3-letter codes were not properly defined
      subset <- sheet[(sheet$treatment %in% trts) == F,] # select all lines with 3-letter codes not properly defined
      for(row in 1:NROW(subset)){ # begin iteration over the 3-letter codes that were not properly defined
        logwarn(paste(paste(subset[row,], collapse = ' - '),": treatment was not properly defined", sep=""),  logger = "") # write warning onto log file
      } # end iteration over the 3-letter codes that were not properly defined
      sheet <- sheet[sheet$treatment %in% trts,]  # discard row
    } # end check on 3-letter codes


    #### Subplot ####

    subplots <- c(as.data.frame(dbGetQuery(con, "SELECT * FROM subplots")))[[1]] # list all codes in the codes table

    if(NROW(sheet[(sheet$subplot %in% subplots) == F,])>0){ # check if some 3-letter codes were not properly defined
      subset <- sheet[(sheet$subplot %in% subplots) == F,] # select all lines with 3-letter codes not properly defined
      for(row in 1:NROW(subset)){ # begin iteration over the 3-letter codes that were not properly defined
        logwarn(paste(paste(subset[row,], collapse = ' - '),": subplot was not properly defined", sep=""),  logger = "") # write warning onto log file
      } # end iteration over the 3-letter codes that were not properly defined
      sheet <- sheet[sheet$subplot %in% subplots,]  # discard row
    } # end check on 3-letter codes


    #### Row ####

    rows <- c(as.data.frame(dbGetQuery(con, "SELECT * FROM rows")))[[1]] # list all codes in the codes table

    if(NROW(sheet[(sheet$row %in% rows) == F,])>0){ # check if some 3-letter codes were not properly defined
      subset <- sheet[(sheet$row %in% rows) == F,] # select all lines with 3-letter codes not properly defined
      for(row in 1:NROW(subset)){ # begin iteration over the 3-letter codes that were not properly defined
        logwarn(paste(paste(subset[row,], collapse = ' - '),": row was not properly defined", sep=""),  logger = "") # write warning onto log file
      } # end iteration over the 3-letter codes that were not properly defined
      sheet <- sheet[sheet$row %in% rows,]  # discard row
    } # end check on 3-letter codes




    # ----- Complete Database -----

    # list all code, treatment, subplot, and row combinations already in the database
    codes.yield <- as.data.frame(dbGetQuery(con, "SELECT * FROM yield"))


    for (obs in 1:NROW(sheet)) { # begin iteration over observations in spreadsheet


      code.value <- sheet$code[obs]; trt.value <- sheet$treatment[obs]
      subplot.value <- sheet$subplot[obs]; row.value <- sheet$row[obs]

      if(NROW(codes.yield[codes.yield$code == code.value & codes.yield$treatment == trt.value & codes.yield$subplot == subplot.value & codes.yield$row == row.value,]) == 0) { # if observation was not in database

        temp <- data.frame(code = sheet$code[obs], treatment = sheet$treatment[obs], subplot = sheet$subplot[obs],
                           row = sheet$row[obs], harvest_wt = sheet$harvest_wt[obs], moisture_1 = sheet$moisture_1[obs], moisture_2 = sheet$moisture_2[obs],
                           percent_lint = sheet$percent_lint[obs],  grain_test_wt1 = sheet$grain_test_wt1[obs],
                           grain_test_wt2 = sheet$grain_test_wt2[obs], notes = sheet$notes[obs],
                           row_spacing = sheet$row_spacing[obs], stand_count = sheet$stand_count[obs], stringsAsFactors = F)

        dbWriteTable(con, "yield", value = temp, append=T, row.names=F) # add observation into database
        loginfo(paste("ADDED:",paste(temp, collapse = ' - ')), logger = "") # complete log file

      } # ends if observation was not already in database


      if(NROW(codes.yield[codes.yield$code == code.value & codes.yield$treatment == trt.value & codes.yield$subplot == subplot.value & codes.yield$row == row.value,]) > 0) { # if observation was already in database

        # extract information available for that producer in database
        check <- dbGetQuery(con, paste("SELECT * FROM yield WHERE code ='",sheet$code[obs],"' AND treatment = '", sheet$treatment[obs],
                                       "' AND subplot = '", sheet$subplot[obs], "' AND row = '", sheet$row[obs], "'", sep=""))

        data.equal <- T # variable defined to test if changes were made in the  google sheet

        temp <- data.frame(code = sheet$code[obs], treatment = sheet$treatment[obs], subplot = sheet$subplot[obs],
                           row = sheet$row[obs], harvest_wt = sheet$harvest_wt[obs], moisture_1 = sheet$moisture_1[obs], moisture_2 = sheet$moisture_2[obs],
                           percent_lint = sheet$percent_lint[obs],  grain_test_wt1 = sheet$grain_test_wt1[obs],
                           grain_test_wt2 = sheet$grain_test_wt2[obs], notes = sheet$notes[obs],
                           row_spacing = sheet$row_spacing[obs], stand_count = sheet$stand_count[obs], stringsAsFactors = F)

        for (col in 2:NCOL(check)){  # check column by columns if what is in google sheet matches what is in the DB
          if((is.na(check[,col]) == T & is.na(temp[,col-1]) == T)==F){ # make sure both values are not NA
            if (identical(as.character(check[,col]), as.character(temp[,col-1])) == F ){data.equal <- F} # if difference, set variable to False
          }}


        if(data.equal == F) { # if data entry are not equal, update DB

          if (is.na(temp$row_spacing[1])==T) {temp$row_spacing[1] <- '0'} # account for null data
          if (is.na(temp$stand_count[1])==T) {temp$stand_count[1] <- '0'} # account for null data
          if (is.na(temp$harvest_wt[1])==T) {temp$harvest_wt[1] <- '0'} # account for null data
          if (is.na(temp$moisture_1[1])==T) {temp$moisture_1[1] <- '0'} # account for null data
          if (is.na(temp$moisture_2[1])==T) {temp$moisture_2[1] <- '0'} # account for null data
          if (is.na(temp$percent_lint[1])==T) {temp$percent_lint[1] <- '0'} # account for null data
          if (is.na(temp$grain_test_wt1[1])==T) {temp$grain_test_wt1[1] <- '0'} # account for null data
          if (is.na(temp$grain_test_wt2[1])==T) {temp$grain_test_wt2[1] <- '0'} # account for null data
          if (is.na(temp$notes[1])==T) {temp$notes[1] <- '[null]'} # account for null data


          update <- paste("UPDATE yield SET row_spacing='", temp$row_spacing[1],
                          "', stand_count='", temp$stand_count[1],
                          "', harvest_wt='", temp$harvest_wt[1],
                          "', moisture_1='", temp$moisture_1[1],
                          "', moisture_2='", temp$moisture_2[1],
                          "', percent_lint='", temp$percent_lint[1],
                          "', grain_test_wt1='", temp$grain_test_wt1[1],
                          "', grain_test_wt2='", temp$grain_test_wt1[1],
                          "', notes='", temp$notes[1],
                          "' WHERE code ='", temp$code[1], "' AND treatment = '", temp$treatment[1],
                          "' AND subplot = '", temp$subplot[1], "' AND  row = '", temp$row[1], "'", sep="") # define SQL query

          dbGetQuery(con, update) # update DB
          loginfo(paste("MODIFIED: OLD: ",paste(check, collapse = ' - ')), logger = "") # complete log file
          loginfo(paste("MODIFIED: NEW: ",paste(temp, collapse = ' - ')), logger = "") # complete log file


        } # end if statement checking if the two entries are equal
      } # end if statement checking if producer is already in database
    } # end iteration over observations in spreadsheet
  } # end iteration over google sheets

  nullif <- "UPDATE yield SET row_spacing =NULLIF(row_spacing, '0'), stand_count = NULLIF(stand_count, '0'),  harvest_wt = NULLIF(harvest_wt, '0'),
             moisture_1 = NULLIF(moisture_1, '0'), moisture_2 = NULLIF(moisture_2, '0'),  percent_lint = NULLIF(percent_lint, '0'), grain_test_wt1 = NULLIF(grain_test_wt1, '0'),
             grain_test_wt2 = NULLIF(grain_test_wt2, '0'), notes = NULLIF(notes, '[null]')"


  dbGetQuery(con, nullif)


  # ----- Delete observations which are not used anymore -----

  yield.db <- data.frame(dbGetQuery(con, "SELECT * FROM yield")) # select all producer_ids existing in DB

  yield.list <- within(yield.list, uniqueid <- paste(code, treatment, subplot, row))
  yield.db <- within(yield.db, uniqueid <- paste(code, treatment, subplot, row))

  # select data to delete
  yield.db <- yield.db[(yield.db$uniqueid %in% yield.list$uniqueid) == F,]

  # delete data from database
  if(NROW(yield.db)>0){
    for(obs in 1:NROW(yield.db)){
      delete <- paste("DELETE FROM yield WHERE code = '", yield.db$code[obs], "' AND treatment = '",
                      yield.db$treatment[obs], "' AND subplot = '", yield.db$subplot[obs],
                      "' AND row = '", yield.db$row[obs], "'", sep="")

      dbGetQuery(con, delete)
      loginfo(paste("DELETED:",paste(yield.db[obs,], collapse = ' - ')), logger = "") # complete log file
    }}

  loginfo("Table: farm_history", logger = "")
  loginfo(paste("Time end:", Sys.time()), logger="")


} # end functionn to import farm_history
