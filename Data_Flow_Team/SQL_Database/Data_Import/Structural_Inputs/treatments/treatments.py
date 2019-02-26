# -*- coding: utf-8 -*-
""" The objective of this script is to import treatments into the CROWN postgresql database. """

# ----- Preliminary Coding -----

# import required packages

import os  # to define work directory
import psycopg2 # import required module to connect to postgresql database
import csv

# set work directory
os.chdir("/Users/amponcet/Documents/GitHub/CROWN/Data_Flow_Team/SQL_Database/Data_Import/Structural_Inputs/treatments") 
print(os.getcwd()) # print current work directory


# ----- Import Data from csv file -----

# import data from csv file
with open('treatments.csv', newline='') as csvfile:
     treatments = csv.reader(csvfile, delimiter=' ', quotechar='|')
     treatments_list = list(treatments)
     
# remove first observation in list (column name)
treatments_list = treatments_list[1:(len(treatments_list)+1)] 
print(len(treatments_list)) 

# format codes values
treatments_list2 = treatments_list

for item in range(0,len(treatments_list2)):
    treatments_list2[item] = (str(treatments_list2[item])[2],)
    


# ----- Define function to update Postgresql database -----
            

# define function to insert all possible unique 3-letter codes into the CROWN database "codes" table
def import_treatments(treatments_list):

    sql = "INSERT INTO treatments(treatment) VALUES(%s)" 
    conn = None
    
    try:
    
        # connect to the PostgreSQL database
        conn = psycopg2.connect(host="localhost", port = "5432", dbname="CROWN_FieldData",  user="admin", password="CROWNadmin18-22")

        # create a new cursor
        cur = conn.cursor()
        
        # execute the INSERT statement
        cur.executemany(sql,treatments_list)
        
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
import_treatments(treatments_list2)
     