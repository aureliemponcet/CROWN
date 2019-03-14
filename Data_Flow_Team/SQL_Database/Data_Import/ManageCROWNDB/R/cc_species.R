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


  # Make sure than families correspond to primary key
  families <- c(as.data.frame(dbGetQuery(con, "SELECT * from cc_families")))[[1]]
  ccspecies$cc_family[ccspecies$cc_family %in%  families == FALSE]  <- NA

  # select data already existing in table
  query <- as.data.frame(dbGetQuery(con, "SELECT * from cc_species"))


  if (NROW(query) > 0){ # if there are observations within the table

    for(obs in seq(NROW(ccspecies),1,by=-1)){ # look at each observation in data

      # if (ccspecies$cc_specie[obs] %in% query$cc_specie & ccspecies$cc_family[obs] %in% query$cc_family){ # if observation already in table
      #   ccspecies <- ccspecies[-obs,] # ignore it
      # }

      # # if observation already in table but family must be updated
      # if (ccspecies$cc_specie[obs] %in% query$cc_specie & (ccspecies$cc_family[obs] %in% query$cc_family == F)){
      #
      #   dbGetQuery(con, paste("UPDATE cc_species SET cc_specie = '",ccspecies$cc_specie[obs],
      #                                                "', cc_family = '", ccspecies$cc_family[obs],
      #                                                "' WHERE cc_specie = '", ccspecies$cc_specie[obs], "'", sep=""))
      #
      # }

      ## Issue with null statement and NULL values


      # if observation not in table
      # if (ccspecies$cc_specie[obs] %in% query$cc_specie == F)){
      #
      #   # add data into database
      #   dbWriteTable(con, "cc_species", value = ccspecies[obs,], append=T, row.names=F)
      #
      #   loginfo("ADDED", logger = "") # complete log file
      #   loginfo(paste(ccspecies[obs,], collapse = ' - '), logger = "") # complete log file


      } # end iteration over observations in data
    } # end if statement

    ccspecies <- as.data.frame(ccspecies[ccspecies$cc_species %in% query$cc_species == FALSE,])
    colnames(ccspecies) <- "cc_species"
  }

  if(NROW(query) == 0){ # if there are no observations in table

    # add data into database
    dbWriteTable(con, "cc_species", value = ccspecies, append=T, row.names=F)

    loginfo("ADDED", logger = "") # complete log file
    for(obs in 1:NROW(ccspecies)){
      loginfo(paste(ccspecies[obs,], collapse = ' - '), logger = "") # complete log file
    }

  }

  loginfo("Table: cc_species", logger = "")
  loginfo(paste("Time end:", Sys.time()), logger="")


} # end function
