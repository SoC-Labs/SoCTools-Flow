#!/bin/bash
#-----------------------------------------------------------------------------
# Autoconfig Setup Library
# A joint work commissioned on behalf of SoC Labs, under Arm Academic Access license.
#
# Contributors
#
# David Mapstone (d.a.mapstone@soton.ac.uk)
#
# Copyright  2023-6, SoC Labs (www.soclabs.org)
#-----------------------------------------------------------------------------
# Description:
# This library provides functions for detecting and configuring development tools
# including ARM toolchains and HDL simulators. The configuration is written to
# the autoconfig file for use by the build system.
#
# Available functions:
# - setup_toolchain: Detects ARM toolchains (DS-5, DS-6, GCC)
# - setup_simulator: Detects HDL simulators (ModelSim, VCS, Cadence, Icarus)
# - setup_all: Runs both toolchain and simulator setup
#-----------------------------------------------------------------------------

# Function to create the autoconfig file that specifies the toolchain
setup_toolchain() {    
    # Define toolchain mappings
    declare -A toolchain_map=(
        ["armasm"]="ds5"
        ["armclang"]="ds6"
        ["arm-none-eabi-gcc"]="gcc"
    )

    # Check for available toolchain
    found_toolchain=false
    for tool in "${!toolchain_map[@]}"; do
        if type -P "$tool" >/dev/null 2>&1; then
            echo "TOOL_CHAIN = ${toolchain_map[$tool]}" > autoconfig
            echo "Found toolchain: ${toolchain_map[$tool]} (using $tool)"
            found_toolchain=true
            break
        fi
    done
    
    # Error if there are no compilers found
    if [ "$found_toolchain" = false ]; then
        echo "ERROR: No ARM software compiler found"
        return 1
    fi
    
    return 0
}

# Function to create the autoconfig file that specifies the simulator
setup_simulator() {    
    # Define simulator mappings
    declare -A simulator_map=(
        ["vsim"]="mti"
        ["vcs"]="vcs" 
        ["xm"]="gcc"
        ["iverilog"]="iverilog"
    )

    # Check for available simulator
    found_simulator=false
    for tool in "${!simulator_map[@]}"; do
        if type -P "$tool" >/dev/null 2>&1; then
            echo "SIMULATOR = ${simulator_map[$tool]}" >> autoconfig
            echo "Found simulator: ${simulator_map[$tool]} (using $tool)"
            found_simulator=true
            break
        fi
    done
    
    # Error if there are no simulators found
    if [ "$found_simulator" = false ]; then
        echo "ERROR: No HDL simulator found"
        return 1
    fi
    
    return 0
}

# Function to setup both toolchain and simulator
setup_all() {
    setup_toolchain
    setup_simulator
    echo "Autoconfig setup completed. Configuration written to autoconfig file."
}