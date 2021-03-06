ImportAppliedChemicals <- function(){ # begin function to import applied_chemicals

  # ----- Complete Log File -----

  loginfo("Table: applied_chemicals", logger = "")
  loginfo(paste("Time ini:", Sys.time()), logger="")

  # ----- Connect to postgresql database -----

  con <- ConnectToDB() # connect to postgresql database
  on.exit(dbDisconnect(con)) # on exit, close connection

  # ----- Create file to store all applied chemicals present in the FieldManagement sheets -----

  chem.list <- data.frame(codes=character(), chemical=character(), stringsAsFactors = F)


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
    sheet <- sheet[,c(1,23:26)] # select desired columns
    colnames(sheet) <- c("code", "termination", "chemical1", "chemical2", "chemical3")

    # remove spaces within chemical names
    sheet$chemical1 <- gsub(" ", "", sheet$chemical1); sheet$chemical2 <- gsub(" ", "", sheet$chemical2); sheet$chemical3 <- gsub(" ", "", sheet$chemical3)
    sheet$chemical1[sheet$chemical1 == "24-D"] <- "2 4-D"; sheet$chemical2[sheet$chemical2 == "24-D"] <- "2 4-D"; sheet$chemical3[sheet$chemical3 == "24-D"] <- "2 4-D"


    # ----- Make sure data satisfy the foreign key constraint -----

    ## codes
    codes <- c(as.data.frame(dbGetQuery(con, "SELECT * FROM codes")))[[1]]

    if(NROW(sheet[(sheet$code %in% codes) == F,])>0){ # check if some 3-letter codes were not properly defined
      subset <- sheet[(sheet$code %in% codes) == F,] # select all lines with 3-letter codes not properly defined
      for(row in 1:NROW(subset)){ # begin iteration over the 3-letter codes that were not properly defined
        logwarn(paste(paste(subset[row,], collapse = ' - '),": 3-letter farm code was not properly defined", sep=""),  logger = "") # write warning onto log file
      } # end iteration over the 3-letter codes that were not properly defined
      sheet <- sheet[sheet$code %in% codes,]  # discard row
    } # end check on 3-letter codes



    ## chemicals
    chemicals <- c(as.data.frame(dbGetQuery(con, "SELECT * FROM chemical_names")))[[1]]

    if(NROW(sheet[(sheet$chemical1 %in% chemicals) == F & is.na(sheet$chemical1) == F,])>0){ # check if chemical1 is on the list of all chemicals
      subset <- sheet[(sheet$chemical1 %in% chemicals) == F & is.na(sheet$chemical1) == F,] # select all lines with chemical1 not properly defined
      for(row in 1:NROW(subset)){ # begin iteration over the cc specie that were not properly defined
        logwarn(paste(paste(subset[row,], collapse = ' - '),": chemical name was not properly defined",sep = ""),  logger = "") # write warning onto log file
      } # end iteration over the 3-letter codes that were not properly defined
      sheet$chemical1[(sheet$chemical1 %in% chemicals) == F & is.na(sheet$chemical1) == F] <- '[null]' # define chemical1 null
    } # end check on chemical1

    if(NROW(sheet[(sheet$chemical2 %in% chemicals) == F & is.na(sheet$chemical2) == F,])>0){ # check if chemical2 is on the list of all chemicals
      subset <- sheet[(sheet$chemical2 %in% chemicals) == F & is.na(sheet$chemical2) == F,] # select all lines with chemical2 not properly defined
      for(row in 1:NROW(subset)){ # begin iteration over the cc specie that were not properly defined
        logwarn(paste(paste(subset[row,], collapse = ' - '),": chemical name was not properly defined",sep = ""),  logger = "") # write warning onto log file
      } # end iteration over the 3-letter codes that were not properly defined
      sheet$chemical2[(sheet$chemical2 %in% chemicals) == F & is.na(sheet$chemical2) == F] <- '[null]' # define chemical2 null
    } # end check on chemical2

    if(NROW(sheet[(sheet$chemical3 %in% chemicals) == F & is.na(sheet$chemical3) == F,])>0){ # check if chemical3 is on the list of all chemicals
      subset <- sheet[(sheet$chemical3 %in% chemicals) == F & is.na(sheet$chemical3) == F,] # select all lines with chemical3 not properly defined
      for(row in 1:NROW(subset)){ # begin iteration over the cc specie that were not properly defined
        logwarn(paste(paste(subset[row,], collapse = ' - '),": chemical name was not properly defined",sep = ""),  logger = "") # write warning onto log file
      } # end iteration over the 3-letter codes that were not properly defined
      sheet$chemical3[(sheet$chemical3 %in% chemicals) == F & is.na(sheet$chemical3) == F] <- '[null]' # define chemical3 null
    } # end check on chemical3


    rm(codes); rm(chemicals) # clean  workspace


    # format sheet for data import
    temp1 <- sheet[,c(1,3)]; temp2 <- sheet[,c(1,4)]; temp3 <- sheet[,c(1,5)]
    colnames(temp1) <- colnames(temp2) <- colnames(temp3) <- c("code", "chemical")
    sheet2 <- rbind(temp1, temp2, temp3)
    rm(temp1); rm(temp2); rm(temp3)


    # remove all observations where specie is NA or [null] and order data
    sheet2 <- sheet2[is.na(sheet2$chemical) == F & sheet2$chemical != '[null]',]
    sheet2 <- sheet2[order(sheet2$code),]
    rm(sheet)

    # add applied chemicals to list
    chem.list <- rbind(chem.list, sheet2[,1:2])



    # ----- Complete Database -----

    # list all codes and chemicals already in the database
    codes.c <- as.data.frame(dbGetQuery(con, "SELECT * FROM applied_chemicals"))
    if(NROW(codes.c) == 0) {codes.c <- data.frame(code =character(), chemical = character())} # if nothing in table set to 0


    for (obs in 1:NROW(sheet2)) { # begin iteration over observations in sheet

      code.value <- sheet2$code[obs]; chem.value <- sheet2$chemical[obs]

      if(NROW(codes.c[codes.c$code == code.value & codes.c$chemical == chem.value,]) == 0) { # if code/chemical combination is not already in database

        temp <- data.frame(code = sheet2$code[obs], chemical = sheet2$chemical[obs], stringsAsFactors = F)
        dbWriteTable(con, "applied_chemicals", value = temp, append=T, row.names=F) # add observation into database
        loginfo(paste("ADDED:",paste(temp, collapse = ' - ')), logger = "") # complete log file

      } # end if statement checking if code/specie combination is already in database

    } # end iteration over observations in sheet

  } # end iteration over google sheets


  # ----- Delete chemicals  which are not used anymore -----

  chem.db <- data.frame(dbGetQuery(con, "SELECT * FROM applied_chemicals")) # select all chemicals existing in DB
  colnames(chem.list) <- colnames(chem.db)[2:3]

  # select data to delete
  chem.db <- chem.db[(chem.db$code %in% chem.list$code & chem.db$chemical %in% chem.list$chemical) == F,]

  # delete data from database
  if(NROW(chem.db)>0){
    for(obs in 1:NROW(chem.db)){
      delete <- paste("DELETE FROM applied_chemicals WHERE code = '", chem.db$code[obs], "'", sep="")
      dbGetQuery(con, delete)
      loginfo(paste("DELETED:",paste(chem.db[obs,], collapse = ' - ')), logger = "") # complete log file
    }}


  loginfo("Table: applied_chemicals", logger = "")
  loginfo(paste("Time end:", Sys.time()), logger="")



} # end function to import applied_chemicals
