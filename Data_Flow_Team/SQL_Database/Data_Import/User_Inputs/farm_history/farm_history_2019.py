# -*- coding: utf-8 -*-
""" This script import farm history  into the CROWN postgresql database. """

# ----- Preliminary Coding -----

# import required modules
import logging # to complete log file
import time # for timestamp
import datetime # for timestamp

# import user-define functions
import sys 
sys.path.insert(0, '/Users/amponcet/Documents/GitHub/CROWN/Data_Flow_Team/SQL_Database/Data_Import/User_Inputs')
import connect_to_googlesheet_API as connectg # to connect with google API
import read_googlesheet as rgsheet # to read google spreadsheet
import check_add_update_db as db # to check, add, and update data in postgresql database


# define function to import 2019 farm history data into database.
def import_farm_history(filename):
    
    # add table name and timestamp to log file
    logging.info('TABLE: ' + 'farm_history')
    logging.info('TIMESTAMP: ' + str(datetime.datetime.fromtimestamp(time.time()).strftime('%Y-%m-%d_%H:%M:%S')))
    

    # define variables to imnport data from google spreadsheet
    SPREADSHEET_ID = '1YjaHe8eVsdV0TV6tadF3KSgcylfjDHeduUHRE1-uN3s'
    RANGE_NAME = 'FieldHist_CC_Crop_N!A2:AO'
    
    
    # ----- Read Data from Google Sheet ----
    
    # connect to google sheet
    gsheet = connectg.get_google_sheet(SPREADSHEET_ID, RANGE_NAME)
    
    # read data from google sheet
    df = rgsheet.gsheet2df(gsheet)
    
    #print(df[0]) # print headers, debug
    #print(df[1]) # print rows, # debug
    
    
    # ----- Update Database ----
    
    for obs in range(0, len(df[1])): # begin iteration over rows
        
       while len(df[1][obs]) < 42: # complete list if missing data at the end
           df[1][obs].extend([None])
           
           # list data in proper format for import in database
#           list_data = [df[1][obs][i] for i in [0,17,18,1,26,27,19,28,20,21,2,22,16,29,35,30,31,32,33,34]]
#           list_data.extend([None])
#           list_data.extend([df[1][obs][i] for i in [36,37,38]])
#           list_data.extend([None])
#           list_data,extend([df[1][obs][i] for i in [39,40,41]])
#           
           
           list_data = [df[0][i] for i in [0,17,18,1,25,26,19,27,]]
           list_data.extend([None])
           list_data.extend([df[0][i] for i in [36,37,38]])
           list_data.extend([None])
           list_data.extend([df[0][i] for i in [39,40,41]])
        
           
           
           
        
        
        
        
        

           
            # list data in proper format for import in database
            list_data = [df[1][obs][i] for i in [0,1,2,7,3,4]]
            list_data.extend([''.join(c for c in df[1][obs][5] if c.isdigit())]) # format phone number
            list_data.extend([df[1][obs][6]]) # address
             
            # format longitude and latitude data
            if df[1][obs][8] != None and df[1][obs][8] != '' : # check if lat/lon data were filled
                list_data.extend([str(df[1][obs][8]).split(', ')[1],str(df[1][obs][8]).split(', ')[0]])
           
            else: list_data.extend([None,None]) # if lat/lon were not filled, no value.
            
            list_data.extend([df[1][obs][i] for i in [9,10]]) # add notes and additional_contact information
            
                            
            # format data for upload into postgresql
            for item in range(0, len(list_data)): # begin iteration over list elements
                if str(list_data[item]) != 'None': # if value is not missing
                    list_data[item] = str(list_data[item]).replace('\n','') # remove "enters"
                list_data[item] = (list_data[item],) # make it a tuple
            
            
            # Select observation 3-letter farm code
            code_value = df[1][obs][0]
         
        
            # Check if data already in database
            sql_exist = "SELECT * FROM site_information WHERE code = '" + code_value + "'"
            check_summary = db.check_data_in_db(sql_exist, code_value)
                
            if len(check_summary) == 0 :
                is_data_in_database = False
                    
            else:
                is_data_in_database = True
                
          
            
            # If data not already in database, add it
            if is_data_in_database == False:
                
                # add data to database ...
                sql_add = "INSERT INTO site_information(code, year, state, county, last_name, email, phone, address, longitude, latitude, notes, additional_contact) VALUES(%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)"    
                db.add_data_to_db(sql_add, list_data)
                
                # ... and complete log file
                logging.info('ADDED TO DB:' + str(df[1][obs]))

            
            # if data is already in database, compare to see if any changes were made
            else: 
                
                # we assume that no changes were made
                same_data = True
                changes = [] # if changes were made, we will store old and new values in this list.
                items_list = ['code', 'year', 'state', 'county', 'last_name', 'email', 'phone', 'address', 'longitude', 'latitude', 'notes', 'additional_contact'] # list column names for reference purposes
                
                # iteration over the different columns
                for item in range(1, len(check_summary[0])):
                    
                    # looks at value in database
                    value1 = str(check_summary[0][item])
                    
                    # looks at value in google spreadsheet
                    if item == 9 or item == 10 :
                        if list_data[item-1] != (None,) and list_data[item-1] != ('',):
                            value2 = str(round(float(str(list_data[item-1])[2:len(str(list_data[item-1]))-3]),4))
                        else:
                            value2 = 'None'
                            
                    else:
                        if list_data[item-1] != (None,) and list_data[item-1] != None:
                            value2 = str(list_data[item-1])[2:len(str(list_data[item-1]))-3]
                        else: 
                            value2 = 'None'
                    
                         
                    # compare the two values. If different, complete the change list and set same_data to False
                    if value1 != value2:
                        changes.extend(["Column = " + str(items_list[item-1]) + " old value = " + str(value1) + " new value = " + str(value2)])                       
                        same_data = False
                                   
                                   
                # if not the same data, then update database and complete log file
                if same_data == False:
                        
                    
                    sql_update = "UPDATE site_information SET code = %s, year = %s, state = %s, county = %s, last_name = %s, email = %s,  phone = %s, address = %s, longitude = %s, latitude = %s, notes = %s, additional_contact = %s  WHERE code = '" + code_value + "'"
                    db.update_data_in_db(sql_update, list_data)
                         
                    logging.info('MODIFIED INTO DB:' + str(changes))
                        
                        
                                    

            
                    
                    
                    
       
        
        


