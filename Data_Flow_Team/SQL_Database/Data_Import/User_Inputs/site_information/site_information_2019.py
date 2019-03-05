# -*- coding: utf-8 -*-
""" This script import cover crop species into the CROWN postgresql database. """

# ----- Preliminary Coding -----

# import required modules
import psycopg2 

# import functions
import sys
sys.path.insert(0, '/Users/amponcet/Documents/GitHub/CROWN/Data_Flow_Team/SQL_Database/Data_Import/User_Inputs')
import connect_to_googlesheet_API as connectg
import read_googlesheet as rgsheet
import connect_to_postgresql as connectpg


# define variables
SPREADSHEET_ID = '1YjaHe8eVsdV0TV6tadF3KSgcylfjDHeduUHRE1-uN3s'
RANGE_NAME = 'START_Sites!A2:K'


# ----- Read Data from Google Sheet ----

# connect to google sheet
gsheet = connectg.get_google_sheet(SPREADSHEET_ID, RANGE_NAME)

# read data from google sheet
df = rgsheet.gsheet2df(gsheet)

#print(df[0]) # print headers, debug
#print(df[1]) # print rows, # debug


# ----- Define Functions ----

def check_data_in_db(sql_exist, code_value):
   
    conn = None
    try:
        conn = connectpg.connect_to_postgresql()
        cur = conn.cursor()
        cur.execute(sql_exist, code_value)
        rows = cur.fetchall()
        conn.commit()
        cur.close()
        
    except (Exception, psycopg2.DatabaseError) as error:
        print(error)
        
    finally:
        if conn is not None:
            conn.close()
        
    return rows    

def add_data_to_db(sql_add, list_data):
   
    conn = None
    try:
        conn = connectpg.connect_to_postgresql()
        cur = conn.cursor()
        cur.execute(sql_add, list_data)
        conn.commit()
        cur.close()
        
    except (Exception, psycopg2.DatabaseError) as error:
        print(error)
        
    finally:
        if conn is not None:
            conn.close()


def update_data_in_db(sql_update, list_data):
    
    conn = None
    try:
        conn = connectpg.connect_to_postgresql()
        cur = conn.cursor()
        cur.execute(sql_update, list_data)
        conn.commit()
        cur.close()
        
    except (Exception, psycopg2.DatabaseError) as error:
        print(error)
        
    finally:
        if conn is not None:
            conn.close()
          


# ----- Update Database ----

for obs in range(0, len(df[1])): # begin iteration over rows
    if len(df[1][obs]) > 1: # make sure 3-letter code was attributed to a farm.
        
       
        # list data in proper format for import in database
        list_data = [df[1][obs][i] for i in [0,1,2,7,3,4]]
        list_data.extend([''.join(c for c in df[1][obs][5] if c.isdigit())]) # format phone number
        list_data.extend([df[1][obs][6]])
  
      
        # check if longitude and latitude were filled
        if len(df[1][obs]) >= 9 and df[1][obs][8] != '':
            list_data.extend([str(df[1][obs][8]).split(', ')[1],str(df[1][obs][8]).split(', ')[0]])
       
        else: list_data.extend(['',''])
        
        
        # check if there are any notes
        if len(df[1][obs]) >= 10 and df[1][obs][9] != '':
            list_data.extend([df[1][obs][9]])
        else:
            list_data.extend([''])
            
        
        # check if there are any additional contact 
        if len(df[1][obs]) == 11:
            list_data.extend([df[1][obs][10]])
        else:
            list_data.extend([''])
            
            
        # format data for upload into postgresql
        for item in range(0, len(list_data)):
            list_data[item] = (list_data[item],)
        
        
        # Select code
        code_value = df[1][obs][0]
        print(code_value) # debug 
        
    
        # Check if data already in database
        sql_exist = "SELECT * FROM site_information WHERE code = '" + code_value + "'"
        check_summary = check_data_in_db(sql_exist, code_value)
            
        if len(check_summary) == 0 :
            is_data_in_database = False
                
        else:
            is_data_in_database = True
            
      
        
        # If data not already in database, add it
        if is_data_in_database == False:
            
            sql_add = "INSERT INTO site_information(code, year, state, county, last_name, email, phone, address, longitude, latitude, notes, additional_contact) VALUES(%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)"    
            add_data_to_db(sql_add, list_data)
            
        
        # if data is already in database, compare to see if any changes were made
        else: 
            
            # we assume that no changes were made
            same_data = True
            
            # iteration over the different columns
            for item in range(1, len(check_summary)):
                
                # looks at value in database
                value1 = str(check_summary[item])
                
                # looks at alue in google spreadsheet
                if item == 9 or item == 10:
                    value2 = str(round(float(str(list_data[item-1])[2:len(str(list_data[item-1]))-3]),4))
                    
                else:
                    value2 = str(list_data[item-1])[2:len(str(list_data[item-1]))-3]
                
                # compare the two values. If different set same data to False
                if value1 != value2:
                    same_data = False
                               
                               
                # if not the same data, then update database
                if same_data == False:
                    
                    sql_update = "UPDATE site_information SET code = %s, year = %s, state = %s, county = %s, last_name = %s, email = %s,  phone = %s, address = %s, longitude = %s, latitude = %s, notes = %s, additional_contact = %s  WHERE code = '" + code_value + "'"
                    update_data_in_db(sql_update, list_data)
                                     
                                    
                        
                    
                    
                    
                    
                    
                    
                
                
# log file
# date time table
# Addition
# ---- added line 
# Update                     
# ---- modified lines                     

                    
                    
                    
            
                    
                
                  
             
            
        
        
      
        
        


