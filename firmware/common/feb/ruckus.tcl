# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load local Source Code and constraints
loadSource      -dir  "$::DIR_PATH/core"
loadSource      -dir  "$::DIR_PATH/pgp"
loadSource      -dir  "$::DIR_PATH/rx"
loadConstraints -dir  "$::DIR_PATH/xdc"
