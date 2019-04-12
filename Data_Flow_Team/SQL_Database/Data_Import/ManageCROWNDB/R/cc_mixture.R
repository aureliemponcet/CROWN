ImportCCMixture <- function(){ # begin function to import cc_mixture

  # ----- Complete Log File -----

  loginfo("Table: cc_mixture", logger = "")
  loginfo(paste("Time ini:", Sys.time()), logger="")

  # ----- Connect to postgresql database -----

  con <- ConnectToDB() # connect to postgresql database
  on.exit(dbDisconnect(con)) # on exit, close connection

  # ----- Create file to store all cover crop mixtures present in the FieldManagement sheets -----

  mixture.list <- data.frame(codes=character(), specie=character(), stringsAsFactors = F)

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
    sheet <- sheet[,c(1,5:16)] # select desired columns
    colnames(sheet) <- c("code", "specie1", "rate1", "specie2", "rate2","specie3", "rate3", "specie4", "rate4", "specie5", "rate5", "specie6", "rate6")

    # convert data from wide to long
    temp1 <- sheet[,c(1,2:3)]; temp2 <- sheet[,c(1,4:5)]; temp3 <- sheet[,c(1,6:7)]
    temp4 <- sheet[,c(1,8:9)]; temp5 <- sheet[,c(1,10:11)]; temp6 <- sheet[,c(1,12:13)]
    colnames(temp1) <- colnames(temp2) <- colnames(temp3) <- colnames(temp4) <- colnames(temp5) <- colnames(temp6) <- c("code", "specie", "rate")
    sheet2 <- rbind(temp1, temp2, temp3, temp4, temp5, temp6) # merge temporary datasets
    rm(temp1); rm(temp2); rm(temp3); rm(temp4); rm(temp5); rm(temp6); rm(sheet) # clean workspace

    # ----- Make sure data satisfy the foreign key constraint -----

    # list all codes in the codes table
    codes <- c(as.data.frame(dbGetQuery(con, "SELECT * FROM codes")))[[1]]

    # list all cc_species in the cc_species table
    species <- c(as.data.frame(dbGetQuery(con, "SELECT * FROM cc_species")))[[1]]

    ## codes
    if(NROW(sheet2[(sheet2$code %in% codes) == F,])>0){ # check if some 3-letter codes were not properly defined
      subset <- sheet2[(sheet2$code %in% codes) == F,] # select all lines with 3-letter codes not properly defined
      for(row in 1:NROW(subset)){ # begin iteration over the 3-letter codes that were not properly defined
        logwarn(paste(subset$state[row],": ",paste(subset[row,], collapse = ' - '),": 3-letter farm code was not properly defined", sep=""),  logger = "") # write warning onto log file
      } # end iteration over the 3-letter codes that were not properly defined
      sheet2 <- sheet2[sheet2$code %in% codes,]  # discard row
    } # end check on 3-letter codes

    ## cc_species
    if(NROW(sheet2[(sheet2$specie %in% species) == F & is.na(sheet2$specie) == F,])>0){ # check if some state were not properly defined
      subset <- sheet2[(sheet2$specie %in% species) == F & is.na(sheet2$specie) == F,] # select all lines with cc species not properly defined
      for(row in 1:NROW(subset)){ # begin iteration over the cc specie that were not properly defined
        logwarn(paste(subset$state[row],": ",paste(subset[row,], collapse = ' - '),": cover crop specie was not properly defined",sep = ""),  logger = "") # write warning onto log file
      } # end iteration over the 3-letter codes that were not properly defined
      sheet2$specie[(sheet2$specie %in% species) == F & is.na(sheet2$specie) == F] <- '[null]' # define cc specie null
    } # end check on states

    rm(codes); rm(species) # clean workspace

    # remove all observations where specie is NA or [null] and order data
    sheet2 <- sheet2[is.na(sheet2$specie) == F & sheet2$specie != '[null]',]
    sheet2 <- sheet2[order(sheet2$code),]

    # add mixture to list
    mixture.list <- rbind(mixture.list, sheet2[,1:2])



    # ----- Complete Database -----

    # list all codes and species already in site_information in the database
    codes.sp <- as.data.frame(dbGetQuery(con, "SELECT * FROM cc_mixture"))
    if(NROW(codes.sp) == 0) {codes.sp <- data.frame(code =character(), cc_specie = character())} # if nothing in table set to 0


    for (obs in 1:NROW(sheet2)) { # begin iteration over observations in sheet2

      code.value <- sheet2$code[obs]; specie.value <- sheet2$specie[obs]
      if(NROW(codes.sp[codes.sp$code == code.value & codes.sp$cc_specie == specie.value,]) == 0) { # if code/specie combination is not already in database

        temp <- data.frame(code = sheet2$code[obs], cc_specie = sheet2$specie[obs], rate = sheet2$rate[obs], stringsAsFactors = F)
        dbWriteTable(con, "cc_mixture", value = temp, append=T, row.names=F) # add observation into database
        loginfo(paste("ADDED:",paste(temp, collapse = ' - ')), logger = "") # complete log file

      } # end if statement checking if code/specie combination is already in database

      if(NROW(codes.sp[codes.sp$code == code.value & codes.sp$cc_specie == specie.value,]) > 0) { # if code and specie combination is already in database

        # extract information available for that producer in database
        check <- dbGetQuery(con, paste("SELECT * FROM cc_mixture WHERE code ='",sheet2$code[obs],"' AND cc_specie = '", sheet2$specie[obs], "'", sep=""))

        data.equal <- T # variable defined to test if changes were made in the  google sheet
        temp <- data.frame(code = sheet2$code[obs],  cc_specie = sheet2$specie[obs], rate = sheet2$rate[obs], stringsAsFactors = F)

        if(identical(as.character(check$rate), as.character(sheet2$rate[obs])) == F){
          data.equal <- F
        }

        if(data.equal == F) { # if data entry are not equal, update DB

          if (is.na(temp$rate[1])==T) {temp$rate[1] <- 0} # account for null data

          update <- paste("UPDATE cc_mixture SET rate = '", temp$rate[1],
                          "' WHERE code ='", temp$code[1], "'AND cc_specie = '", temp$cc_specie[1], "'", sep="") # define SQL query

          dbGetQuery(con, update) # update DB
          loginfo(paste("MODIFIED: OLD: ",paste(check, collapse = ' - ')), logger = "") # complete log file
          loginfo(paste("MODIFIED: NEW: ",paste(temp, collapse = ' - ')), logger = "") # complete log file


        } # end if statement updating databse if data entry were not equal


      } # end if statement checking if code/specie combination is already in database
    } # end iteration over observations in sheet2
  } # end iteration over google sheets

  # nullify NAs
  nullif <- "UPDATE cc_mixture SET rate =NULLIF(rate, '0')"
  dbGetQuery(con, nullif)

  # ----- Delete mixtures  which are not used anymore -----

  mixture.db <- data.frame(dbGetQuery(con, "SELECT * FROM cc_mixture")) # select all producer_ids existing in DB
  colnames(mixture.list) <- colnames(mixture.db)[2:3]

  # select data to delete
  mixture.db <- mixture.db[(mixture.db$code %in% mixture.list$code & mixture.db$cc_specie %in% mixture.list$cc_specie) == F,]

  # delete data from database
  if(NROW(mixture.db)>0){
    for(obs in 1:NROW(mixture.db)){
      delete <- paste("DELETE FROM cc_mixture WHERE code = '", mixture.db$code[obs], "'", sep="")
      dbGetQuery(con, delete)
      loginfo(paste("DELETED:",paste(mixture.db[obs,], collapse = ' - ')), logger = "") # complete log file
    }}


  loginfo("Table: cc_mixture", logger = "")
  loginfo(paste("Time end:", Sys.time()), logger="")

} # end function to import cc_mixture
