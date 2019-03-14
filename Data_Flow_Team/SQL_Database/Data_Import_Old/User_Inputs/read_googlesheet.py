# -*- coding: utf-8 -*-
""" This script creates a function to read data from the google spreadsheet """


def gsheet2df(gsheet):
    """ Import data from google spreadsheet""" 

    header = gsheet.get('values', [])[0]   # Assumes first line is header!
    values = gsheet.get('values', [])[1:]  # Everything else is data.
    return (header, values)

