# import required libraries
require(tidyr)

# set work directory
setwd("~/Documents/GitHub/CROWN/Data_Flow_Team/SQL_Database/Data_Import/Structural_Inputs/codes")

## create all possible three letter codes

codes <- crossing(LETTERS,LETTERS,LETTERS)  # calculate all possible combinations
codes.vector <- c() # create an empty list

for(row in 1:NROW(codes)){ # begin iteration over row
  codes.vector <- c(codes.vector,paste(codes[row,1],codes[row,2],codes[row,3], sep="")) # concatenate codes
} # end iteration over row

codes <- data.frame(codes = codes.vector) # store all possible three letter codes in table

# export results into a csv file
write.table(codes,"codes.csv",  row.names=F, sep=",")

