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
        match = re.match(r'(?!\s*#)\s+(.*):\s*(.*)\s*$', line.strip())
        if match:
            repo_name, branch_name = match.groups()
            sub_repos.append(git_repo(repo_name, branch_name))
    return sub_repos

def find_branchfile(directory, branchfile):
    """ This function locates the branchfiles, reads them and then causes a checkout of all the subrepos. """
    if exists(f"{directory}/{branchfile}"):
        print(f"Found Branchfile in {directory}")
        for repo in read_branchfile(f"{directory}/{branchfile}"):
            print(f"Subrepo found: {repo.directory}")
            repo_checkout(f"{directory}/{repo.directory}", repo.branch, branchfile)
        
            # Look for branchfiles in the subrepos
            find_branchfile(repo.directory, branchfile)
    else:
        print(f"No branchfile present in {directory}")
    
def repo_checkout(directory, branch, branchfile):
    """ Checkout the repository on a specific branch. """
    print(f"Checking out {directory} to branch {branch}")
    os.system(f"cd {directory}; git checkout --recurse-submodules {branch}")
    os.system(f"cd {directory}; git pull")
    find_branchfile(directory, branchfile)
    #TODO: make this work recursively over each subrepo
    
if __name__ == "__main__":
    # Capture Arguments from Command Line
    parser = argparse.ArgumentParser(description='Checks out branches for subrepositories in a project')
    parser.add_argument("-b", "--branchfile", type=str, help="File to Read in Branches from")
    parser.add_argument("-t", "--topproject", type=str, help="Top-level directory of Project")
    args = parser.parse_args()
    print("Running subrepo checkout")
    find_branchfile(args.topproject, args.branchfile)
