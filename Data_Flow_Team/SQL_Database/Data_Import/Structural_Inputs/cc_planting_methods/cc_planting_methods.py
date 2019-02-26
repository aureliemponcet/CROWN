# -*- coding: utf-8 -*-
""" The objective of this script is to import all cover crop planting methods into the CROWN postgresql database. """

# ----- Preliminary Coding -----

# import required packages

import os  # to define work directory
import psycopg2 # import required module to connect to postgresql database
import csv

# set work directory
os.chdir("/Users/amponcet/Documents/GitHub/CROWN/Data_Flow_Team/SQL_Database/Data_Import/Structural_Inputs/cc_planting_methods") 
print(os.getcwd()) # print current work directory


# ----- Import Data from csv file -----

# import data from csv file
with open('cc_planting_methods.csv', newline='') as csvfile:
     methods = csv.reader(csvfile, delimiter=' ', quotechar='|')
     methods_list = list(methods)
     
# remove first observation in list (column name)
methods_list = methods_list[1:(len(methods_list)+1)] 
print(len(methods_list)) 


# concatenate words when values include spaces
for row in range(0,len(methods_list)):
    if len(methods_list[row]) > 1 :
        temp = str(methods_list[row][0])
        for element in range(1,len(methods_list[row])):
            temp = str(temp) + " " + str(methods_list[row][element])
        methods_list[row] = [temp]
            


# format codes values
methods_list2 = methods_list

for item in range(0,len(methods_list2)):
    methods_list2[item] = (str(methods_list2[item])[2:(len(str(methods_list2[item]))-2)],)
    


# ----- Define function to update Postgresql database -----
            

# define function to insert all possible unique 3-letter codes into the CROWN database "codes" table
def import_methods(methods_list):

    sql = "INSERT INTO cc_planting_methods(cc_planting_method) VALUES(%s)" 
    conn = None
    
    try:
    
        # connect to the PostgreSQL database
        conn = psycopg2.connect(host="localhost", port = "5432", dbname="CROWN_FieldData",  user="admin", password="CROWNadmin18-22")

        # create a new cursor
        cur = conn.cursor()
        
        # execute the INSERT statement
        cur.executemany(sql,methods_list)
        
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
import_methods(methods_list2)
    