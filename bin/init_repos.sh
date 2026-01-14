#-----------------------------------------------------------------------------
# SoC Labs Environment Setup Script
# A joint work commissioned on behalf of SoC Labs, under Arm Academic Access license.
#
# Contributors
#
# David Mapstone (d.a.mapstone@soton.ac.uk)
#
# Copyright  2026, SoC Labs (www.soclabs.org)
#-----------------------------------------------------------------------------
# Description:
# This script is used to locate Makefiles with setup_repo targets within project 
# subrepositories and execute it to set up repository-specific configurations.
#-----------------------------------------------------------------------------

#!/bin/bash

# Parse command line options
force=false
unset_mode=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--force)
            force=true
            echo "Forcing repository operation"
            shift
            ;;
        --unset)
            unset_mode=true
            shift
            ;;
        *)
            echo "Unknown option $1"
            echo "Usage: $0 [-f|--force] [--unset]"
            exit 1
            ;;
    esac
done

find_subrepos() {
    # Create a list of subrepositories to initialize (recursively)
    local subrepos=()
    while IFS= read -r repo; do
        [[ -n "$repo" ]] && subrepos+=("$repo")
    done < <(git submodule foreach --recursive --quiet 'echo $PWD')
    
    # Return the list of subrepositories found
    printf '%s\n' "${subrepos[@]}"
}

# Function to find repositories that contain setup_repo targets
find_repos_with_setup() {
    local subrepos=("$@")
    local setup_repos=()
    
    echo -e "\n\033[1;35m-----------------------------------------------" >&2
    echo "Scanning for Makefiles with setup_repo targets" >&2
    echo -e "-----------------------------------------------\033[0m" >&2
        
    for repo in "${subrepos[@]}"; do
        # Find all Makefiles at the top level of each subrepository
        while IFS= read -r makefile; do
            if [[ -n "$makefile" ]]; then
                # Check if this Makefile contains a setup_repo target
                if grep -q "^setup_repo:" "$makefile" 2>/dev/null; then
                    setup_repos+=("$makefile")
                    echo -e "Found setup_repo target in: \033[0;32m$makefile\033[0m" >&2
                fi
            fi
        done < <(find "$repo" -maxdepth 1 \( -name "makefile" -o -name "Makefile" -o -name "Makefile.*" \) -type f)
    done
    
    echo -e "\n\033[1;35mSummary: Found ${#setup_repos[@]} Makefiles with setup_repo targets\033[0m" >&2
    
    # Return the list of repositories with setup scripts
    printf '%s\n' "${setup_repos[@]}"
}

# Function to find repositories that contain unset_repo targets
find_repos_with_unset() {
    local subrepos=("$@")
    local unset_repos=()
    
    echo -e "\n\033[1;35m-----------------------------------------------" >&2
    echo "Scanning for Makefiles with unset_repo targets" >&2
    echo -e "-----------------------------------------------\033[0m" >&2
        
    for repo in "${subrepos[@]}"; do
        # Find all Makefiles at the top level of each subrepository
        while IFS= read -r makefile; do
            if [[ -n "$makefile" ]]; then
                # Check if this Makefile contains an unset_repo target
                if grep -q "^unset_repo:" "$makefile" 2>/dev/null; then
                    unset_repos+=("$makefile")
                    echo -e "Found unset_repo target in: \033[0;32m$makefile\033[0m" >&2
                fi
            fi
        done < <(find "$repo" -maxdepth 1 \( -name "makefile" -o -name "Makefile" -o -name "Makefile.*" \) -type f)
    done
    
    echo -e "\n\033[1;35mSummary: Found ${#unset_repos[@]} Makefiles with unset_repo targets\033[0m" >&2
    
    # Return the list of repositories with unset scripts
    printf '%s\n' "${unset_repos[@]}"
}

# Function to display all subrepositories found
display_subrepos() {
    local subrepos=("$@")
    
    echo -e "\n\033[1;35m-----------------------------------------------"
    echo "Locating Subrepositories in Project"
    echo -e "-----------------------------------------------\033[0m"
    for repo in "${subrepos[@]}"; do
        echo -e "Found subrepository: \033[0;32m$repo\033[0m"
    done
    echo -e "\n\033[1;35mTotal subrepositories found: ${#subrepos[@]}\033[0m"
}

# Main function to initialize all subrepositories
init_repos() {
    local force_flag=$1
    
    # Find all subrepositories
    local all_subrepos=()
    mapfile -t all_subrepos < <(find_subrepos)
    
    # Display found subrepositories
    display_subrepos "${all_subrepos[@]}"
    
    # Find repositories with setup scripts
    echo "Finding repositories with setup repo makefile targets..."
    local setup_repos=()
    mapfile -t setup_repos < <(find_repos_with_setup "${all_subrepos[@]}")
    
    if [ ${#setup_repos[@]} -eq 0 ]; then
        echo -e "\n\033[1;35mNo repositories with setup_repo targets found. Nothing to initialize.\033[0m"
        return 0
    fi
    
    # Run the setup_repo target in each found repository
    echo -e "\n\033[1;35m-----------------------------------------------"
    echo "Initializing each Subrepository"
    echo -e "-----------------------------------------------\033[0m"
    for makefile in "${setup_repos[@]}"; do
        local repo_dir
        repo_dir=$(dirname "$makefile")
        makefile_name=$(basename "$makefile")
        
        # Check if force flag is set or if repository needs initialization
        if [ "$force_flag" = true ]; then
            echo -e "Force initializing repository: \033[0;32m$repo_dir\033[0m using \033[0;32m$makefile_name\033[0m"
        else
            echo -e "Initializing repository: \033[0;32m$repo_dir\033[0m using \033[0;32m$makefile_name\033[0m"
        fi
                                                                                                        
        # Change terminal colour and run the setup_repo target
        echo -e "\033[0;33m"
        if [ "$force_flag" = true ]; then
            make -f "$makefile" -B setup_repo
        else
            make -f "$makefile" setup_repo
        fi
        echo -e "\033[0m"
    done
    return 0
}

# Main function to unset all subrepositories
unset_repos() {
    # Find all subrepositories
    local all_subrepos=()
    mapfile -t all_subrepos < <(find_subrepos)
    
    # Display found subrepositories
    display_subrepos "${all_subrepos[@]}"
    
    # Find repositories with unset scripts
    echo "Finding repositories with unset repo makefile targets..."
    local unset_repos=()
    mapfile -t unset_repos < <(find_repos_with_unset "${all_subrepos[@]}")
    
    if [ ${#unset_repos[@]} -eq 0 ]; then
        echo -e "\n\033[1;35mNo repositories with unset_repo targets found. Nothing to unset.\033[0m"
        return 0
    fi
    
    # Run the unset_repo target in each found repository
    echo -e "\n\033[1;35m-----------------------------------------------"
    echo "Unsetting each Subrepository"
    echo -e "-----------------------------------------------\033[0m"
    for makefile in "${unset_repos[@]}"; do
        local repo_dir
        repo_dir=$(dirname "$makefile")
        makefile_name=$(basename "$makefile")
        
        echo -e "Unsetting repository: \033[0;32m$repo_dir\033[0m using \033[0;32m$makefile_name\033[0m"
                                                                                                        
        # Change terminal colour and run the unset_repo target
        echo -e "\033[0;33m"
        make -f "$makefile" unset_repo
        echo -e "\033[0m"
    done
    return 0
}

# Execute the appropriate function based on mode
if [ "$unset_mode" = true ]; then
    echo -e "\n\033[1;31m-----------------------------------------------"
    echo "Uninitializing Subrepositories"
    echo -e "-----------------------------------------------\033[0m"
    unset_repos
else
    echo -e "\n\033[1;34m-----------------------------------------------"
    echo "Initializing Subrepositories"
    echo -e "-----------------------------------------------\033[0m"
    init_repos "$force"
fi