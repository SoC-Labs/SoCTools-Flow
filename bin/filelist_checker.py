#!/usr/bin/env python3
#------------------------------------------------------------------------------------
# Verilog Filelist compilation script
# A joint work commissioned on behalf of SoC Labs, under Arm Academic Access license.
#
# Contributors
#
# David Mapstone (d.a.mapstone@soton.ac.uk)
# Copyright (c) 2023, SoC Labs (www.soclabs.org)
#------------------------------------------------------------------------------------
# Description:
# This script checks to see if the files in a given file list exist. If they do not,
# it returns a list of files it fails to find.
#------------------------------------------------------------------------------------
import argparse
import os
import logging
import sys
    
def filelist_checker(input_filelist, debug_level="INFO"):
    """ Function for checking the existance of files within a given filelist. """
    # Create a logging file
    log = logging.getLogger(__name__)
    stdout_handler = logging.StreamHandler(stream=sys.stdout)
    log.addHandler(stdout_handler)
    log.setLevel(debug_level)
    log.info(f"Checking Input Filelist: {input_filelist}")
    
    f_inlist = open(input_filelist, "r")
    filelist_lines = f_inlist.readlines()
    f_inlist.close()
    
    # Create a list of missing files
    missing_files = []
    for line in filelist_lines:
        # Ensure line is not commented or isn't a command word
        line = line.strip()
        if (not ((line.startswith("//")) or (line.startswith("#")) or (line.startswith("+")))):
            file_path = os.path.abspath(line)
            if (not os.path.exists(file_path)):
                missing_files.append(file_path)
    
    # Check if any files are missing
    if len(missing_files) > 0:
        log.error("The following files were not found:")
        for missing in missing_files:
            log.error(f" - {missing}")
    else:
        log.info("All files were found successfully.")

if __name__ == "__main__":
    # Capture Arguments from Command Line
    parser = argparse.ArgumentParser(description='Compiles Filelist to Read')
    parser.add_argument("-i", "--input", type=str, help="Input Filelist to Read")
    parser.add_argument("--loglevel", default="INFO")
    args = parser.parse_args()
    filelist_checker(args.input, args.loglevel)
