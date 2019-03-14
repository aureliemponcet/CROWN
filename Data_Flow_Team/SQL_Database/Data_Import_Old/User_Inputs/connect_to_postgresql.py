# -*- coding: utf-8 -*-
""" This script creates a function to connect to postgresql database """

# import required modules
import psycopg2   # module to connect to postgresql database

# import configuration file
import sys
sys.path.insert(0, '/Users/amponcet/Desktop')
import configuration


# define function to connect to postgresql database
def connect_to_postgresql():
    
    # read database configuration
    params = configuration.config()
        
    # connect to the PostgreSQL database
    conn = psycopg2.connect(**params)
    
    return conn

