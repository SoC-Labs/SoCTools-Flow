#-----------------------------------------------------------------------------
# SoC Labs Environment Setup Script
# A joint work commissioned on behalf of SoC Labs, under Arm Academic Access license.
#
# Contributors
#
# David Mapstone (d.a.mapstone@soton.ac.uk)
#
# Copyright  2023, SoC Labs (www.soclabs.org)
#-----------------------------------------------------------------------------
#!/bin/bash
OPTIND=1

# Get Root Location of Design Structure
if [ -z $SOCLABS_PROJECT_DIR ]; then
    echo -e "\n\033[1;35m==============================================="
    echo "project_setup.sh: Locating SoC Labs Project Root"
    echo -e "===============================================\033[0m"
                                                                 
    # If $SOCLABS_PROJECT_DIR hasn't been set yet
    # - Find the top-level repository that is not a submodule of another repo
    CURRENT_DIR=`git rev-parse --show-toplevel`
    while true; do
        SUPERPROJECT=`git -C "$CURRENT_DIR" rev-parse --show-superproject-working-tree 2>/dev/null`
        if [ -z "$SUPERPROJECT" ]; then
            # No superproject found, this is the top-level repo
            SOCLABS_PROJECT_DIR="$CURRENT_DIR"
            break
        else
            # Move up to the superproject and check again
            CURRENT_DIR="$SUPERPROJECT"
        fi
    done
    
    echo "SoC Labs Project Root located at: $SOCLABS_PROJECT_DIR"
    export SOCLABS_PROJECT_DIR

    # Source Top-Level Sourceme
    source $SOCLABS_PROJECT_DIR/set_env.sh
else
    echo -e "\n\033[1;35m==============================================="
    echo "project_setup.sh: Project Root Already Set"
    echo -e "===============================================\033[0m"
                                                                 
    # Source dependency environment variable script
    # TODO: Look into doing this in a cleaner way
    source $SOCLABS_PROJECT_DIR/env/dependency_env.sh
fi

# Parse Command line options
force=false
while getopts "f" arg; do
    case $arg in
        f) # Force socinit
            force=true
            echo "Forcing Reinitialisation of Project"
            ;;
    esac
done

# Check cloned repository has been initialised
if [ ! -f $SOCLABS_PROJECT_DIR/.socinit ] || [ $force = true ]; then
    echo -e "\n\033[1;35m==============================================="
    echo "project_setup.sh: Running First Time Repository Initialisation"
    echo -e "===============================================\033[0m"
                                                                 
    # Update all submodules in the repository
    cd $SOCLABS_PROJECT_DIR
    git submodule update --recursive
    python3 $SOCLABS_SOCTOOLS_FLOW_DIR/bin/subrepo_checkout.py -b projbranch -t $SOCLABS_PROJECT_DIR
    git restore $SOCLABS_PROJECT_DIR/.gitmodules
    touch $SOCLABS_PROJECT_DIR/.socinit
    echo "SoC Labs File Initialisation file: This file has been created to show that the project has been initialised" > $SOCLABS_PROJECT_DIR/.socinit
fi
