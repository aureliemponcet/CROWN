# -*- coding: utf-8 -*-
""" The objective of this script is to import all cash crops into the CROWN postgresql database. """

# ----- Preliminary Coding -----

# import required packages
import os  # to define work directory
import psycopg2 # import required module to connect to postgresql database
import csv

# import configuration file
import sys
sys.path.insert(0, '/Users/amponcet/Desktop')
import configuration

# set work directory
os.chdir("/Users/amponcet/Documents/GitHub/CROWN/Data_Flow_Team/SQL_Database/Data_Import/Structural_Inputs/cash_crops") 
print(os.getcwd()) # print current work directory


# ----- Import Data from csv file -----

# import data from csv file
with open('cash_crops.csv', newline='') as csvfile:
     ccrops = csv.reader(csvfile, delimiter=' ', quotechar='|')
     ccrops_list = list(ccrops)
     
# remove first observation in list (column name)
ccrops_list = ccrops_list[1:(len(ccrops_list)+1)] 
print(len(ccrops_list)) 


# concatenate words when values include spaces
for row in range(0,len(ccrops_list)):
    if len(ccrops_list[row]) > 1 :
        temp = str(ccrops_list[row][0])
        for element in range(1,len(ccrops_list[row])):
            temp = str(temp) + " " + str(ccrops_list[row][element])
        ccrops_list[row] = [temp]
            


# format codes values
ccrops_list2 = ccrops_list

for item in range(0,len(ccrops_list2)):
    ccrops_list2[item] = (str(ccrops_list2[item])[2:(len(str(ccrops_list2[item]))-2)],)
    


# ----- Define function to update Postgresql database -----
            

# define function to insert all possible unique 3-letter codes into the CROWN database "codes" table
def import_cash_crops(ccrops_list):

    sql = "INSERT INTO cash_crops(cash_crop) VALUES(%s)" 
    conn = None
    
    try:
    
        # read database configuration
        params = configuration.config()
        
        # connect to the PostgreSQL database
        conn = psycopg2.connect(**params)

        # create a new cursor
        cur = conn.cursor()
        
        # execute the INSERT statement
        cur.executemany(sql,ccrops_list)
        
        # commit the changes to the database
        conn.commit()
        
        # close communication with the database
        cur.close()
        
    except (Exception, psycopg2.DatabaseError) as error:
        print(error)
        
    finally:
        if conn is not None:
            conn.close()
            


# ----- Update Postgresql database -----

# execute function to complete the code table
import_cash_crops(ccrops_list2)
    