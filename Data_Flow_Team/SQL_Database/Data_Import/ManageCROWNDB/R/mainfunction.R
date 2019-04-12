MainFunction <- function(){ # begin MainFunction()

  # ----- Preliminary Coding -----

  # import required libraries
  require(tidyr)
  require(RPostgreSQL)
  require(googlesheets)
  require(reshape2)

  # define where to find configuration file
  source("~/Desktop/configuration.R")

  # ----- Set up Log File -----

  require(logging); basicConfig()
  addHandler(writeToFile, logger="", file=paste("~/Documents/GitHub/CROWN/Data_Flow_Team/SQL_Database/Data_Import/log_files/log_",Sys.Date(),".log",sep=""))

  # ----- Import Structural Inputs -----

  # ImportCodes()
  # ImportCashCrops()
  # ImportCCFamilies()
  # ImportCCPlantingMethods()
  # ImportCCTerminationMethods()
  # ImportCCSpecies()
  # ImportDepths()
  # ImportRows()
  # ImportSeasons()
  # ImportSoilSubsamples()
  # ImportSubplots()
  # ImportSubsamples()
  # ImportStates()
  # ImportTexturalClasses()
  # ImportTimes()
  # ImportTreatments()
  # ImportTypes()
  # ImportChemicalFamilies()
  # ImportChemicalNames()

  # ----- Access Google Drive  -----

  # gs_auth(new_user = TRUE)


  # ----- Import User Inputs -----

  #### Georgia - 2018 ####

  # ImportProducerIds()
  # ImportSiteInfo()
  # ImportCCMixture()
  # ImportAppliedChemicals()
  # ImportFarmHistory()
  ImportYield()




} # end MainFunction()
