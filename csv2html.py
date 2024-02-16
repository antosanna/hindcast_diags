# Python program to convert 
# CSV to HTML Table


import pandas as pd

# to read csv file named "samplee"
a = pd.read_csv("/work/csp/cp1/CPS/CMCC-CPS1/logs/hindcast/sps4_hindcast_recover2_list.juno.2024021511.csv")

# to save as html file
# named as "Table"
a.to_html("Table.htm")

# assign it to a 
# variable (string)
html_file = a.to_html()

