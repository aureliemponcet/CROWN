ImportChemicalNames <- function(){ # begin function

  # ----- Complete Log File -----

  loginfo("Table: chemical_names", logger = "")
  loginfo(paste("Time ini:", Sys.time()), logger="")


  # ----- Import data from rda file ----

  data(chemicalnames) # import data from rda file

  # ----- Import data into database -----

  con <- ConnectToDB() # connect to postgresql database
  on.exit(dbDisconnect(con)) # on exit, close connection
  chem <- within(chem, {chemical <- as.character(chemical); chemical_family <- as.character(chemical_family)}) # convert code to character

  # list families in cc_families
  chemfam <- c(as.data.frame(dbGetQuery(con, "SELECT * from chemical_families")))[[1]]

  # select data already existing in table
  query <- as.data.frame(dbGetQuery(con, "SELECT * from chemical_names"))
  loginfo("ADDED", logger = "") # complete log file

  for (obs in 1:NROW(chem)){ # begin iteration over the number of observations in ccspecies

    # check if chemical_family is correct
    if (chem$chemical_family[obs] %in% chemfam == FALSE){ # if family is not in cc_families table
      logwarn(paste(paste(chem[obs,], collapse = ' - '),": chemical family entry does not validate foreign key", sep=""),  logger = "")
    } # end if statement

    if (chem$chemical_family[obs] %in% chemfam == TRUE){ # if family is not in cc_families table

      if (chem$chemical[obs] %in% query$chemical == FALSE){ # if observation not already in table

        # add data into database
        dbWriteTable(con, "chemical_names", value = chem[obs,], append=T, row.names=F)
        loginfo(paste(chem[obs,], collapse = ' - '), logger = "") # complete log file


      }  # end if statement on the number of observations within the table
    } # end if statement on chemical_family

  } # end iteration over the number of observations in ccspecies


  loginfo("Table: chemical_names", logger = "")
  loginfo(paste("Time end:", Sys.time()), logger="")


} # end function
