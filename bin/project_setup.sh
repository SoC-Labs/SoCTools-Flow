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
if [ -z "$SOCLABS_DESIGN_ROOT" ]; then
    # If $SOCLABS_DESIGN_ROOT hasn't been set yet
    SOCLABS_DESIGN_ROOT=`git rev-parse --show-superproject-working-tree`

    if [ -z "$SOCLABS_DESIGN_ROOT" ]; then
        # If not in a submodule - at root
        SOCLABS_DESIGN_ROOT=`git rev-parse --show-toplevel`
    fi
    export SOCLABS_DESIGN_ROOT

    # Entered directly (sourced or executed by hand, not from the project's
    # set_env.sh): hand over to the top-level set_env.sh exactly once, as
    # before, and stop here -- set_env.sh sources this script again with
    # SOCLABS_DESIGN_ROOT now set and does the real work below.
    # Entered FROM set_env.sh: do not re-enter it (that ran the whole
    # environment setup twice, flist generation included); just continue.
    if [[ "${BASH_SOURCE[1]##*/}" != "set_env.sh" ]]; then
        source $SOCLABS_DESIGN_ROOT/set_env.sh
        _soclabs_rc=$?
        return $_soclabs_rc 2>/dev/null || exit $_soclabs_rc
    fi
fi

# Set Environment Variable for Project Dir: walk up from the current
# directory to the first .slprojroot marker, stopping at the filesystem root.
SEARCH_DIR=`pwd`
SEARCH_START_DIR=$SEARCH_DIR
while true
do
    if [[ -f $SEARCH_DIR"/.slprojroot" ]]; then
        export SOCLABS_PROJECT_DIR=$SEARCH_DIR
        break
    elif [[ "$(cd "$SEARCH_DIR" 2>/dev/null && pwd -P)" == "/" ]]; then
        echo "project_setup.sh: ERROR: no .slprojroot marker found walking up from $SEARCH_START_DIR to /" >&2
        echo "  Source this from inside a SoC Labs project (the directory holding .slprojroot)." >&2
        unset SEARCH_DIR SEARCH_START_DIR
        return 1 2>/dev/null || exit 1
    else
        SEARCH_DIR=$SEARCH_DIR/..
    fi
done
unset SEARCH_START_DIR

    # If this Repo is root of workspace
    if [ $SOCLABS_PROJECT_DIR = $SOCLABS_DESIGN_ROOT ]; then
        echo "Design Workspace: $SOCLABS_DESIGN_ROOT" 
        export SOCLABS_DESIGN_ROOT
    fi

    # Add in location for socsim scripts
    export SOCLABS_SOCSIM_PATH=$SOCLABS_PROJECT_DIR/simulate/socsim
    

    # Source dependency environment variable script
    source $SOCLABS_PROJECT_DIR/env/dependency_env.sh

    # Add Scripts to Path
    # "TECH_DIR"
    while read line; do 
        eval PATH="$PATH:\$${line}/flow"
    done <<< "$(awk 'BEGIN{for(v in ENVIRON) print v}' | grep TECH_DIR)"

    # "FLOW_DIR"
    while read line; do 
        eval PATH="$PATH:\$${line}/tools"
    done <<< "$(awk 'BEGIN{for(v in ENVIRON) print v}' | grep FLOW_DIR)"

    # "SOCLABS_PROJECT_DIR"
    while read line; do 
        eval PATH="$PATH:\$${line}/flow"
    done <<< "$(awk 'BEGIN{for(v in ENVIRON) print v}' | grep SOCLABS_PROJECT_DIR)"

    export PATH

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
    echo "Running First Time Repository Initialisation"
    # The sub-repository checkout moves every submodule to the branch named
    # in `projbranch` and pulls it (subrepo_checkout.py). That is only right
    # for a fresh clone of a branch-tracking project; on any checkout already
    # carrying work it silently reverts working trees. So it is opt-in:
    # SOCLABS_SETUP_SUBMODULES=1 in the environment, or -f (explicit re-init).
    if [ "${SOCLABS_SETUP_SUBMODULES:-0}" = "1" ] || [ $force = true ]; then
        # Source environment variables for all submodules
        cd $SOCLABS_DESIGN_ROOT
        echo $SOCLABS_DESIGN_ROOT
        git submodule update --recursive
        python3 $SOCLABS_SOCTOOLS_FLOW_DIR/bin/subrepo_checkout.py -b projbranch -t $SOCLABS_DESIGN_ROOT
        git restore $SOCLABS_DESIGN_ROOT/.gitmodules
    else
        echo "  Skipping 'git submodule update --recursive' and subrepo_checkout.py."
        echo "  Set SOCLABS_SETUP_SUBMODULES=1 (or pass -f) to check out the projbranch sub-repositories."
    fi
    touch $SOCLABS_PROJECT_DIR/.socinit
    echo "SoC Labs File Initialisation file: This file has been created to show that the project has been initialised" > $SOCLABS_PROJECT_DIR/.socinit
fi
