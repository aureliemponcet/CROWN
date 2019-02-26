# -*- coding: utf-8 -*-
""" The objective of this script is to import all states 2-letter code into the CROWN postgresql database. """

# ----- Preliminary Coding -----

# import required packages

import os  # to define work directory
import psycopg2 # import required module to connect to postgresql database
import csv

# set work directory
os.chdir("/Users/amponcet/Documents/GitHub/CROWN/Data_Flow_Team/SQL_Database/Data_Import/Structural_Inputs/seasons") 
print(os.getcwd()) # print current work directory


# ----- Import Data from csv file -----

# import data from csv file
with open('seasons.csv', newline='') as csvfile:
     seasons = csv.reader(csvfile, delimiter=' ', quotechar='|')
     seasons_list = list(seasons)
     
# remove first observation in list (column name)
seasons_list = seasons_list[1:(len(seasons_list)+1)] 
print(len(seasons_list)) 

# format codes values
seasons_list2 = seasons_list

for item in range(0,len(seasons_list2)):
    seasons_list2[item] = (str(seasons_list2[item])[2],)
    


# ----- Define function to update Postgresql database -----
            

# define function to insert all possible unique 3-letter codes into the CROWN database "codes" table
def import_seasons(seasons_list):

    sql = "INSERT INTO seasons(season) VALUES(%s)" 
    conn = None
    
    try:
    
        # connect to the PostgreSQL database
        conn = psycopg2.connect(host="localhost", port = "5432", dbname="CROWN_FieldData",  user="admin", password="CROWNadmin18-22")

        # create a new cursor
        cur = conn.cursor()
        
        # execute the INSERT statement
        cur.executemany(sql,seasons_list)
        
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
import_seasons(seasons_list2)
     