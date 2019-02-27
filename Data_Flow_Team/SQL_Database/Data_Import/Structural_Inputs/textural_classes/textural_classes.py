# -*- coding: utf-8 -*-
""" The objective of this script is to import all soil textural classes into the CROWN postgresql database. """

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
os.chdir("/Users/amponcet/Documents/GitHub/CROWN/Data_Flow_Team/SQL_Database/Data_Import/Structural_Inputs/textural_classes") 
print(os.getcwd()) # print current work directory


# ----- Import Data from csv file -----

# import data from csv file
with open('textural_classes.csv', newline='') as csvfile:
     tclass = csv.reader(csvfile, delimiter=' ', quotechar='|')
     tclass_list = list(tclass)
     
# remove first observation in list (column name)
tclass_list = tclass_list[1:(len(tclass_list)+1)] 
print(len(tclass_list)) 


# concatenate words when values include spaces
for row in range(0,len(tclass_list)):
    if len(tclass_list[row]) > 1 :
        temp = str(tclass_list[row][0])
        for element in range(1,len(tclass_list[row])):
            temp = str(temp) + " " + str(tclass_list[row][element])
        tclass_list[row] = [temp]
            


# format codes values
tclass_list2 = tclass_list

for item in range(0,len(tclass_list2)):
    tclass_list2[item] = (str(tclass_list2[item])[2:(len(str(tclass_list2[item]))-2)],)
    


# ----- Define function to update Postgresql database -----
            

# define function to insert all possible unique 3-letter codes into the CROWN database "codes" table
def import_textural_classes(tclass_list):

    sql = "INSERT INTO textural_classes(tclass) VALUES(%s)" 
    conn = None
    
    try:
    
        # read database configuration
        params = configuration.config()
        
        # connect to the PostgreSQL database
        conn = psycopg2.connect(**params)

        # create a new cursor
        cur = conn.cursor()
        
        # execute the INSERT statement
        cur.executemany(sql,tclass_list)
        
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
import_textural_classes(tclass_list2)
    