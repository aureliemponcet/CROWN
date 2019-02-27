# -*- coding: utf-8 -*-
""" The objective of this script is to import subsamples into the CROWN postgresql database. """

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
os.chdir("/Users/amponcet/Documents/GitHub/CROWN/Data_Flow_Team/SQL_Database/Data_Import/Structural_Inputs/subsamples") 
print(os.getcwd()) # print current work directory


# ----- Import Data from csv file -----

# import data from csv file
with open('subsamples.csv', newline='') as csvfile:
     subsamples = csv.reader(csvfile, delimiter=' ', quotechar='|')
     subsamples_list = list(subsamples)
     
# remove first observation in list (column name)
subsamples_list = subsamples_list[1:(len(subsamples_list)+1)] 
print(len(subsamples_list)) 

# format codes values
subsamples_list2 = subsamples_list

for item in range(0,len(subsamples_list2)):
    subsamples_list2[item] = (str(subsamples_list2[item])[2],)
    

# ----- Define function to update Postgresql database -----
            

# define function to insert all possible unique 3-letter codes into the CROWN database "codes" table
def import_subsamples(subsamples_list):

    sql = "INSERT INTO subsamples(subsample) VALUES(%s)" 
    conn = None
    try:

        # read database configuration
        params = configuration.config()
        
        # connect to the PostgreSQL database
        conn = psycopg2.connect(**params)
        
        # create a new cursor
        cur = conn.cursor()
        
        # execute the INSERT statement
        cur.executemany(sql,subsamples_list)
        
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
import_subsamples(subsamples_list2)
     