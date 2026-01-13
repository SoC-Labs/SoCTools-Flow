#!/usr/bin/env python3
#------------------------------------------------------------------------------------
# Project Subrepository Checkout Script
# A joint work commissioned on behalf of SoC Labs, under Arm Academic Access license.
#
# Contributors
#
# David Mapstone (d.a.mapstone@soton.ac.uk)
# Copyright (c) 2023, SoC Labs (www.soclabs.org)
#------------------------------------------------------------------------------------
# Description:
# This script is used for reading a project branch file which specifies the branches
# each of the subrepositories within the project repository should be set to in order to
# update each of the branches to their head
#------------------------------------------------------------------------------------
import argparse
import os
import re

from os.path import exists
import subprocess

class git_repo():
    """ This is a class which contains the repository name and the branch to check out to. """
    def __init__(self, directory, branch):
        self.directory = directory
        self.branch    = branch
        

def read_branchfile(branchfile):
    """ This function reads the branch files that is present in the repo and 
        lists the sub-repos present """
    f = open(branchfile, "r")
    filelines = f.readlines()
    f.close()
    sub_repos = []
    for line in filelines:
        # Find lines of the format (repo)\s+:\+(branch) that don't start with #
        match = re.match(r'(?!\s*#)\s*(.*):\s*(.*)\s*$', line.strip())
        if match:
            repo_name, branch_name = match.groups()
            sub_repos.append(git_repo(repo_name, branch_name))
    return sub_repos

def find_branchfile(directory, branchfile):
    """ This function locates the branchfiles, reads them and then causes a checkout of all the subrepos. """
    if exists(f"{directory}/{branchfile}"):
        print(f"Found Branchfile in {directory}")
        for repo in read_branchfile(f"{directory}/{branchfile}"):
            # Checkout each repo to the specified branch
            repo_checkout(f"{directory}/{repo.directory}", repo.branch, branchfile)
    
def repo_checkout(directory, branch, branchfile):
    """ Checkout the repository on a specific branch. """
    print(f"Checking out {directory} to branch {branch}")
    # Change to directory and checkout branch
    try:
        result = subprocess.run(["git", "checkout", "--recurse-submodules", branch], 
                       cwd=directory, check=True, capture_output=True, text=True)
        
        # Create a dict to compare the output against
        result_dict  = {
            "Your branch is up to date": "warning"
        }
        
        # Analyze the output
        # Check for specific output patterns
        output_text = result.stdout + result.stderr
        for pattern, level in result_dict.items():
            if pattern not in output_text:
                print(f"Git {level}: {output_text.strip()}")
            break
        else:
            # No specific patterns found, print normal output
            if result.stdout:
                print(f"Checkout output: {result.stdout.strip()}")
            if result.stderr:
                print(f"Checkout warnings: {result.stderr.strip()}")
        
        subprocess.run(["git", "pull"], 
                    cwd=directory, check=True, capture_output=True)
    except subprocess.CalledProcessError as e:
        print(f"Git command failed in {directory}: {e}")
    
    # After checkout, check for branchfile in sub-repository
    find_branchfile(directory, branchfile)
    
if __name__ == "__main__":
    # Capture Arguments from Command Line
    parser = argparse.ArgumentParser(description='Checks out branches for subrepositories in a project')
    parser.add_argument("-b", "--branchfile", type=str, help="File to Read in Branches from")
    parser.add_argument("-t", "--topproject", type=str, help="Top-level directory of Project")
    args = parser.parse_args()
    print("Running Subrepository Checkout Script")
    find_branchfile(args.topproject, args.branchfile)