# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load common and sub-module ruckus.tcl files
loadRuckusTcl $::env(PROJ_DIR)/../../submodules/surf

# Load target's source code and constraints
loadSource -sim_only -dir "$::DIR_PATH/tb"

# Set the top level synth_1 and sim_1
set_property top {XpmAxisFifoTb} [get_filesets sim_1]
