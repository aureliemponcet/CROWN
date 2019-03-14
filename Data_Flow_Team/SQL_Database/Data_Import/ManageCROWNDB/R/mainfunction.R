MainFunction <- function(){ # begin MainFunction()

  # ----- Preliminary Coding -----

  # import required libraries
  require(tidyr)
  require(RPostgreSQL)

  # define where to find configuration file
  source("~/Desktop/configuration.R")

  # ----- Set up Log File -----

  require(logging); basicConfig()
  addHandler(writeToFile, logger="", file=paste("~/Documents/GitHub/CROWN/Data_Flow_Team/SQL_Database/Data_Import/log_",Sys.Date(),".log",sep=""))

  # ----- Import Structural Inputs -----

  # ImportCodes() # codes
  # ImportCashCrops() # cash_crops
  # ImportCCFamilies() # cc_families
  # ImportCCPlantingMethods() # cc_planting_methods
  # ImportCCTerminationMethods() # cc_planting_methods
  # ImportCCSpecies() # cc_planting_methods
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
  ImportTypes()







} # end MainFunction()
