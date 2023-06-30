#!/usr/bin/python3
#-----------------------------------------------------------------------------
# SoCLabs Regression Results Script
#
# Contributors
#
# David Mapstone (d.a.mapstone@soton.ac.uk)
#
# Copyright � 2021-3, SoC Labs (www.soclabs.org)
#-----------------------------------------------------------------------------

from tabulate import tabulate
import sys

def regression_results(results_file):
    file = open(results_file,"r")
    data_lines = file.readlines()
    
    passes   = 0
    fails    = 0
    test_num = 0
    table_data = []
    
    # Read Data in
    for line in data_lines:
        if "PASSED" in line:
            passes += 1
            test_num += 1
        elif "FAILED" in line:
            fails += 1
            test_num += 1
        
        line_data = line.split(" ")
        table_data.append(line_data)
    
    print(tabulate(table_data, headers=["Test Name", "Result"]))
    print("--------------------")
    print(f"PASSES: {passes}/{test_num}")
         
if __name__ == "__main__":
    file = str(sys.argv[1])
    regression_results(file)