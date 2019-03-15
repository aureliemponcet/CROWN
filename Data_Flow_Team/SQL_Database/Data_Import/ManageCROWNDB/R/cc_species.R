ImportCCSpecies <- function(){ # begin function

  # ----- Complete Log File -----

  loginfo("Table: cc_species", logger = "")
  loginfo(paste("Time ini:", Sys.time()), logger="")


  # ----- Import data from rda file ----

  data(ccspecies) # import data from rda file

  # ----- Import data into database -----

  con <- ConnectToDB() # connect to postgresql database
  on.exit(dbDisconnect(con)) # on exit, close connection
  ccspecies <- within(ccspecies, {cc_specie <- as.character(cc_specie); cc_family <- as.character(cc_family)}) # convert code to character

  # list families in cc_families
  families <- c(as.data.frame(dbGetQuery(con, "SELECT * from cc_families")))[[1]]

  # select data already existing in table
  query <- as.data.frame(dbGetQuery(con, "SELECT * from cc_species"))
  loginfo("ADDED", logger = "") # complete log file

  for (obs in 1:NROW(ccspecies)){ # begin iteration over the number of observations in ccspecies

    # check if cc_family is correct
    if (ccspecies$cc_family[obs] %in% families == FALSE){ # if family is not in cc_families table
      logwarn(paste(paste(ccspecies[obs,], collapse = ' - '),": family entry does not validate foreign key", sep=""),  logger = "")
    } # end if statement

    if (ccspecies$cc_family[obs] %in% families == TRUE){ # if family is not in cc_families table

        if (ccspecies$cc_specie[obs] %in% query$cc_specie == FALSE){ # if observation not already in table

          # add data into database
          dbWriteTable(con, "cc_species", value = ccspecies[obs,], append=T, row.names=F)
          loginfo(paste(ccspecies[obs,], collapse = ' - '), logger = "") # complete log file


      }  # end if statement on the number of observations within the table
    } # end if statement on cc_family

  } # end iteration over the number of observations in ccspecies


  loginfo("Table: cc_species", logger = "")
  loginfo(paste("Time end:", Sys.time()), logger="")


} # end function
