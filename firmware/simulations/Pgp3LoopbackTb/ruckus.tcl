# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load common and sub-module ruckus.tcl files
loadRuckusTcl $::env(PROJ_DIR)/../../submodules/surf
loadRuckusTcl $::env(PROJ_DIR)/../../common/shared

# Load target's source code and constraints
loadSource -sim_only -dir "$::DIR_PATH/tb"
loadSource -path "$::DIR_PATH/../../submodules/rce-gen3-fw-lib/RceG3/hdl/RceG3Pkg.vhd"

# Remove the .DCP and use the .XCI IP core instead
remove_files [get_files {*.dcp}]

# Set the top level synth_1 and sim_1
set_property top {PgpProtocolOnly} [get_filesets sources_1]
set_property top {Pgp3LoopbackTb} [get_filesets sim_1]