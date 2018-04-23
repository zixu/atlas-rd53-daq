# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Check for version 2018.1 of Vivado (or later)
if { [VersionCheck 2018.1] < 0 } {exit -1}

# Load local Source Code and constraints
loadSource      -dir  "$::DIR_PATH/rtl"
loadConstraints -dir  "$::DIR_PATH/xdc"
