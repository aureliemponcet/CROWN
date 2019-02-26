# -*- coding: utf-8 -*-
""" The objective of this script is to import all states 2-letter code into the CROWN postgresql database. """

# ----- Preliminary Coding -----

# import required packages

import os  # to define work directory
import psycopg2 # import required module to connect to postgresql database
import csv

# set work directory
os.chdir("/Users/amponcet/Documents/GitHub/CROWN/Data_Flow_Team/SQL_Database/Data_Import/Structural_Inputs/states") 
print(os.getcwd()) # print current work directory


# ----- Import Data from csv file -----

# import data from csv file
with open('states.csv', newline='') as csvfile:
     states = csv.reader(csvfile, delimiter=' ', quotechar='|')
     states_list = list(states)
     
# remove first observation in list (column name)
states_list = states_list[1:(len(states_list)+1)] 
print(len(states_list)) 

# format codes values
states_list2 = states_list

for item in range(0,len(states_list2)):
    states_list2[item] = (str(states_list2[item])[2:4],)
    


# ----- Define function to update Postgresql database -----
            

# define function to insert all possible unique 3-letter codes into the CROWN database "codes" table
def import_states(states_list):

    sql = "INSERT INTO states(state) VALUES(%s)" 
    conn = None
    
    try:
    
        # connect to the PostgreSQL database
        conn = psycopg2.connect(host="localhost", port = "5432", dbname="CROWN_FieldData",  user="admin", password="CROWNadmin18-22")

        # create a new cursor
        cur = conn.cursor()
        
        # execute the INSERT statement
        cur.executemany(sql,states_list)
        
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
import_states(states_list2)
     