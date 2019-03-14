#!/usr/bin/env python3
## -*- coding: utf-8 -*-

""" This script will update the postgresql database through bash """

# ----- Preliminary Coding -----

# import required modules
import logging
import time
import datetime
import sys


# define log filename
filename = 'log_CROWN_' + str(datetime.datetime.fromtimestamp(time.time()).strftime('%Y-%m-%d')) + '.log'
logging.basicConfig(filename=filename, level=logging.INFO)

# ----- Define function to Import Modules -----

def run(runfile):
  with open(runfile,"r") as rnf:
      exec(rnf.read())
    
   
# ----- Site Information Table -----
  
sys.path.insert(0, '/Users/amponcet/Documents/GitHub/CROWN/Data_Flow_Team/SQL_Database/Data_Import/User_Inputs/site_information')
import site_information_2019

if __name__ == '__main__':
#    site_information_2019.import_site_information(filename)


