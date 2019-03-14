# -*- coding: utf-8 -*-
""" This script creates functions to check, add, and update data into database """

# ----- Import required modules and user-defined functions ----

import psycopg2 # to communicate with postgresql database
import connect_to_postgresql as connectpg # to connect with postgresql database


# ----- Define Functions ----

# checks if row is already present in database
def check_data_in_db(sql_exist, code_value):
   
    conn = None
    try:
        conn = connectpg.connect_to_postgresql() # connect to postgresql database
        cur = conn.cursor()
        cur.execute(sql_exist, code_value)  # execute SQL query
        rows = cur.fetchall() # retrieve data from database
        conn.commit()
        cur.close()
        
    except (Exception, psycopg2.DatabaseError) as error:
        print(error)
        
    finally:
        if conn is not None:
            conn.close() # close connection to database
        
    return rows    

# adds new row into database
def add_data_to_db(sql_add, list_data):
   
    conn = None
    try:
        conn = connectpg.connect_to_postgresql() # connect to postgresql database
        cur = conn.cursor()
        cur.execute(sql_add, list_data) # execute SQL query
        conn.commit() 
        cur.close()
        
    except (Exception, psycopg2.DatabaseError) as error:
        print(error)
        
    finally:
        if conn is not None:
            conn.close() # close connection to database

# update existing row into database
def update_data_in_db(sql_update, list_data):
    
    conn = None
    try:
        conn = connectpg.connect_to_postgresql() # connect to postgresql database
        cur = conn.cursor()
        cur.execute(sql_update, list_data) # execute SQL query
        conn.commit()
        cur.close() 
        
    except (Exception, psycopg2.DatabaseError) as error:
        print(error)
        
    finally:
        if conn is not None:
            conn.close() # clost connection to database
          