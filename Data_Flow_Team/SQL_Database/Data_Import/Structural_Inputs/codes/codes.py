# -*- coding: utf-8 -*-
""" The objective of this script is to import all possible unique 3-letter farm codes into the CROWN postgresql database. """

import psycopg2 # import required module to connect to postgresql database
import csv

# define function to insert all possible unique 3-letter codes into the CROWN database "codes" table
def import_codes(code_list):

    sql = "INSERT INTO codes(code_name) VALUES(%s)" 
    conn = None
    
    try:
    
        # connect to the PostgreSQL database
        conn = psycopg2.connect(host="localhost", port = "5432", dbname="CROWN_FieldData",  user="admin", password="CROWNadmin18-22")

        # create a new cursor
        cur = conn.cursor()
        
        # execute the INSERT statement
        cur.executemany(sql,code_list)
        
        # commit the changes to the database
        conn.commit()
        
        # close communication with the database
        cur.close()
        
    except (Exception, psycopg2.DatabaseError) as error:
        print(error)
        
    finally:
        if conn is not None:
            conn.close()
            
            
 codes_csv = csv.reader("codes.csv")