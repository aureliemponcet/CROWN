# -*- coding: utf-8 -*-
""" The objective of this script is to import all chemical families into the CROWN postgresql database. """

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
os.chdir("/Users/amponcet/Documents/GitHub/CROWN/Data_Flow_Team/SQL_Database/Data_Import/Structural_Inputs/chemical_families") 
print(os.getcwd()) # print current work directory


# ----- Import Data from csv file -----

# import data from csv file
with open('chemical_families.csv', newline='') as csvfile:
     cfamilies = csv.reader(csvfile, delimiter=' ', quotechar='|')
     cfamilies_list = list(cfamilies)
     
# remove first observation in list (column name)
cfamilies_list = cfamilies_list[1:(len(cfamilies_list)+1)] 
print(len(cfamilies_list)) 


# concatenate words when values include spaces
for row in range(0,len(cfamilies_list)):
    if len(cfamilies_list[row]) > 1 :
        temp = str(cfamilies_list[row][0])
        for element in range(1,len(cfamilies_list[row])):
            temp = str(temp) + " " + str(cfamilies_list[row][element])
        cfamilies_list[row] = [temp]
            


# format codes values
cfamilies_list2 = cfamilies_list

for item in range(0,len(cfamilies_list2)):
    cfamilies_list2[item] = (str(cfamilies_list2[item])[2:(len(str(cfamilies_list2[item]))-2)],)
    


# ----- Define function to update Postgresql database -----
            

# define function to insert all possible unique 3-letter codes into the CROWN database "codes" table
def import_chemical_families(cfamilies_list):

    sql = "INSERT INTO chemical_families(chemical_family) VALUES(%s)" 
    conn = None
    
    try:
    
        # read database configuration
        params = configuration.config()
        
        # connect to the PostgreSQL database
        conn = psycopg2.connect(**params)

        # create a new cursor
        cur = conn.cursor()
        
        # execute the INSERT statement
        cur.executemany(sql,cfamilies_list)
        
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
import_chemical_families(cfamilies_list2)
    