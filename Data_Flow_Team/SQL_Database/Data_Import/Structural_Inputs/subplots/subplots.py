# -*- coding: utf-8 -*-
""" The objective of this script is to import subplots into the CROWN postgresql database. """

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
os.chdir("/Users/amponcet/Documents/GitHub/CROWN/Data_Flow_Team/SQL_Database/Data_Import/Structural_Inputs/subplots") 
print(os.getcwd()) # print current work directory


# ----- Import Data from csv file -----

# import data from csv file
with open('subplots.csv', newline='') as csvfile:
     subplots = csv.reader(csvfile, delimiter=' ', quotechar='|')
     subplots_list = list(subplots)
     
# remove first observation in list (column name)
subplots_list = subplots_list[1:(len(subplots_list)+1)] 
print(len(subplots_list)) 

# format codes values
subplots_list2 = subplots_list

for item in range(0,len(subplots_list2)):
    subplots_list2[item] = (str(subplots_list2[item])[2],)
    

# ----- Define function to update Postgresql database -----
            

# define function to insert all possible unique 3-letter codes into the CROWN database "codes" table
def import_subplots(subplots_list):

    sql = "INSERT INTO subplots(subplot) VALUES(%s)" 
    conn = None
    try:

        # read database configuration
        params = configuration.config()
        
        # connect to the PostgreSQL database
        conn = psycopg2.connect(**params)
        
        # create a new cursor
        cur = conn.cursor()
        
        # execute the INSERT statement
        cur.executemany(sql,subplots_list)
        
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
import_subplots(subplots_list2)
     