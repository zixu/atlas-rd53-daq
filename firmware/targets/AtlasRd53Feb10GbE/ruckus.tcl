# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load common and sub-module ruckus.tcl files
loadRuckusTcl $::env(PROJ_DIR)/../../submodules/surf
loadRuckusTcl $::env(PROJ_DIR)/../../common/feb

# Load Timon's source code
loadSource -dir "$::env(PROJ_DIR)/../../submodules/HomebrewAurora/RX"
loadSource -dir "$::env(PROJ_DIR)/../../submodules/HomebrewAurora/RX/xapp1017"

# Load local source Code
loadSource      -dir  "$::DIR_PATH/hdl"
loadConstraints -dir  "$::DIR_PATH/hdl"
