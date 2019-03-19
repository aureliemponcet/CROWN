ImportAppliedChemicals <- function(){ # begin function to import applied_chemicals

  # ----- Complete Log File -----

  loginfo("Table: applied_chemicals", logger = "")
  loginfo(paste("Time ini:", Sys.time()), logger="")

  # ----- Connect to postgresql database -----

  con <- ConnectToDB() # connect to postgresql database
  on.exit(dbDisconnect(con)) # on exit, close connection

  # ----- Import data from Google Spreadsheet -----

  # import data from google sheet
  keys <- c("1DXVi4MaEvZ_UbNu-pcT5skeb_4GfMCqS4cNkb494-OE",  # GA2018
            "1Az_8qAfpjVta9vXZFhr3YTsxSsLGHQmGTsPU2Qm27Pg") # GA2017

  for(key in keys){ # begin iteration over google sheets

    sheet <- as.data.frame(gs_read(gs_key(key), ws = "FieldManagement", range = cell_cols(1:44), col_names=T, skip=1)) # import data from googlesheet

    # format data
    sheet <- sheet[is.na(sheet$CODE)==F,]   # remove empty lines
    sheet <- sheet[,c(1,23:26)] # select desired columns
    colnames(sheet) <- c("code", "termination", "chemical1", "chemical2")

    # Select farm codes for which cover crops were terminated using herbicides
    termination <- c(as.data.frame(dbGetQuery(con, "SELECT * FROM cc_termination_methods")))[[1]]
    termination <- termination[grepl("Herbicide", termination)]
    sheet <- sheet[sheet$termination %in% termination,]

    # ----- Make sure data satisfy the foreign key constraint -----













  } # end iteration over google sheets

} # end function to import applied_chemicals
