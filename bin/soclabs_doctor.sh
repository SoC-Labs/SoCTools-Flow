#!/bin/bash
#-----------------------------------------------------------------------------
# SoC Labs tool doctor
# A joint work commissioned on behalf of SoC Labs, under Arm Academic Access license.
#
# Copyright (C) 2026, SoC Labs (www.soclabs.org)
#-----------------------------------------------------------------------------
# Usage:  soclabs_doctor.sh            (or: make doctor, via
#         $(SOCLABS_SOCTOOLS_FLOW_DIR)/bin/soclabs_doctor.sh)
#
# Prints one line per tool the nanoSoC flows need, with the version found or
# MISSING and an install hint, then checks $ARM_QS_IP_DIR (when set) holds the
# two Arm Quickstart directories. The exit code is the verdict: 0 when every
# REQUIRED item is present, 1 otherwise. OPTIONAL items never fail the run.
#
# Environment:
#   SOCLABS_PYTHON   interpreter to check (default: first of python3,
#                    python3.10 .. python3.13 on PATH that is >= 3.10)
#   ARM_QS_IP_DIR    root of the unpacked Cortex-M0 Quickstart bundle
#-----------------------------------------------------------------------------

PY_MIN_MAJOR=3
PY_MIN_MINOR=10
VERILATOR_MIN=5.036

missing_required=0
missing_required_names=""

# row STATUS ITEM VERSION-OR-PATH HINT
row() {
    printf '%-9s %-22s %-38s %s\n' "$1" "$2" "$3" "$4"
}

req_missing() {
    missing_required=$((missing_required + 1))
    missing_required_names="$missing_required_names $1"
    row "MISSING" "$1" "-" "$2"
}

echo "SoC Labs tool doctor"
echo "--------------------"
row "STATUS" "ITEM" "FOUND" "HINT"

# --- python >= 3.10 ----------------------------------------------------------
PY=""
for cand in "${SOCLABS_PYTHON:-}" python3 python3.10 python3.11 python3.12 python3.13; do
    [ -z "$cand" ] && continue
    command -v "$cand" >/dev/null 2>&1 || continue
    ver=$("$cand" -c 'import sys; print("%d.%d.%d" % sys.version_info[:3])' 2>/dev/null) || continue
    maj=${ver%%.*}; rest=${ver#*.}; min=${rest%%.*}
    if [ "$maj" -gt $PY_MIN_MAJOR ] || { [ "$maj" -eq $PY_MIN_MAJOR ] && [ "$min" -ge $PY_MIN_MINOR ]; }; then
        PY=$(command -v "$cand"); PYVER=$ver; break
    fi
    [ -z "$PY_TOO_OLD" ] && PY_TOO_OLD="$cand ($ver)"
done
if [ -n "$PY" ]; then
    row "ok" "python3 >= 3.10" "$PYVER  $PY" "${PY_TOO_OLD:+(python3 on PATH is $PY_TOO_OLD; export SOCLABS_PYTHON=$PY)}"
    for mod in cocotb jinja2 yaml peakrdl_regblock; do
        mver=$("$PY" -c "import $mod; print(getattr($mod, '__version__', 'present'))" 2>/dev/null)
        case $mod in
            yaml)             pipname=pyyaml ;;
            peakrdl_regblock) pipname=peakrdl-regblock ;;
            *)                pipname=$mod ;;
        esac
        if [ -n "$mver" ]; then
            row "ok" "  python: $mod" "$mver" ""
        else
            req_missing "  python: $mod" "$PY -m pip install $pipname"
        fi
    done
else
    req_missing "python3 >= 3.10" "install Python 3.10+ (conda/pyenv/distro) and export SOCLABS_PYTHON=<path>${PY_TOO_OLD:+; python3 on PATH is $PY_TOO_OLD}"
    for mod in cocotb jinja2 yaml peakrdl_regblock; do
        row "SKIPPED" "  python: $mod" "-" "needs a python3 >= 3.10 first"
    done
fi

# --- required CLI tools --------------------------------------------------------
if command -v arm-none-eabi-gcc >/dev/null 2>&1; then
    row "ok" "arm-none-eabi-gcc" "$(arm-none-eabi-gcc -dumpversion 2>/dev/null)  $(command -v arm-none-eabi-gcc)" ""
else
    req_missing "arm-none-eabi-gcc" "Arm GNU Toolchain 10.3+ (developer.arm.com), add its bin/ to PATH"
fi

if command -v make >/dev/null 2>&1; then
    row "ok" "make" "$(make --version 2>/dev/null | head -1 | sed 's/GNU Make //')  $(command -v make)" ""
else
    req_missing "make" "install GNU make (apt install make / dnf install make)"
fi

# one HDL simulator: vcs, xrun, vsim (Questa) or iverilog
sim_found=""
for sim in vcs xrun vsim iverilog; do
    if command -v $sim >/dev/null 2>&1; then
        case $sim in
            iverilog) sv=$(iverilog -V 2>/dev/null | head -1 | sed 's/Icarus Verilog version //; s/ (.*//') ;;
            vcs)      sv=$(vcs -ID 2>/dev/null | grep -m1 'Compiler version' | sed 's/.*= *VCS *//') ;;
            xrun)     sv=$(xrun -version 2>/dev/null | head -1 | awk '{print $NF}') ;;
            vsim)     sv=$(vsim -version 2>/dev/null | head -1 | awk '{print $NF}') ;;
        esac
        row "ok" "simulator: $sim" "${sv:-present}  $(command -v $sim)" ""
        sim_found="$sim_found $sim"
    fi
done
if [ -z "$sim_found" ]; then
    req_missing "simulator" "one of vcs, xrun, vsim, iverilog (free: apt install iverilog, or oss-cad-suite)"
fi

# --- optional tools ---------------------------------------------------------------
if command -v verilator >/dev/null 2>&1; then
    vv=$(verilator --version 2>/dev/null | awk '{print $2}')
    if [ "$(printf '%s\n%s\n' "$VERILATOR_MIN" "$vv" | sort -V | head -1)" = "$VERILATOR_MIN" ]; then
        row "ok" "verilator (optional)" "$vv  $(command -v verilator)" ""
    else
        row "OLD" "verilator (optional)" "$vv  $(command -v verilator)" "need >= $VERILATOR_MIN for the cocotb/lint flows (oss-cad-suite or build from source)"
    fi
else
    row "absent" "verilator (optional)" "-" "optional: >= $VERILATOR_MIN for the cocotb/lint flows"
fi

if command -v vivado >/dev/null 2>&1; then
    row "ok" "vivado (optional)" "$(vivado -version 2>/dev/null | head -1 | awk '{print $2}')  $(command -v vivado)" ""
else
    row "absent" "vivado (optional)" "-" "optional: Vivado 2024.1 for the FPGA flow (source <Vivado>/settings64.sh)"
fi

if command -v openocd >/dev/null 2>&1; then
    row "ok" "openocd (optional)" "$(openocd --version 2>&1 | head -1 | awk '{print $4}')  $(command -v openocd)" ""
else
    row "absent" "openocd (optional)" "-" "optional: OpenOCD 0.12 (or pyOCD) to debug a board over SWD"
fi

# --- Arm Quickstart IP root -----------------------------------------------------------
if [ -n "$ARM_QS_IP_DIR" ]; then
    for d in Cortex-M0-logical Corstone-101-logical; do
        if [ -d "$ARM_QS_IP_DIR/$d" ]; then
            row "ok" "ARM_QS_IP_DIR/$d" "$ARM_QS_IP_DIR/$d" ""
        else
            req_missing "ARM_QS_IP_DIR/$d" "ARM_QS_IP_DIR=$ARM_QS_IP_DIR must contain $d/ (unpacked Cortex-M0 Quickstart bundle)"
        fi
    done
else
    row "unset" "ARM_QS_IP_DIR" "-" "export ARM_QS_IP_DIR=<unpacked Cortex-M0 Quickstart> before building (not checked)"
fi

echo "--------------------"
if [ $missing_required -gt 0 ]; then
    echo "FAIL: $missing_required required item(s) missing:$missing_required_names"
    exit 1
fi
echo "OK: all required tools found"
exit 0
