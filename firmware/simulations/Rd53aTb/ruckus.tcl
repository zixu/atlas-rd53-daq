# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load common and sub-module ruckus.tcl files
loadRuckusTcl $::env(PROJ_DIR)/../../submodules/surf
# loadRuckusTcl $::env(PROJ_DIR)/../../common/shared

# Load target's source code and constraints
loadSource -sim_only -dir "$::DIR_PATH/tb"
loadSource -sim_only -fileType VHDL            -path "$::DIR_PATH/tb/Rd53aTb.vhd"
loadSource -sim_only -fileType SystemVerilog   -path "$::DIR_PATH/tb/Rd53aWrapper.sv"
loadSource -sim_only -fileType SystemVerilog   -path "$::DIR_PATH/RD53A_SIM_DAQ/example_tb.sv"
loadSource -sim_only -fileType {Verilog Header} -dir "$::DIR_PATH/RD53A_SIM_DAQ/"
loadSource -sim_only -fileType {Verilog Header} -dir "$::DIR_PATH/RD53A_SIM_DAQ/sim/common"
loadSource -sim_only -fileType {Verilog Header} -dir "$::DIR_PATH/RD53A_SIM_DAQ/sim/rd53a/dut"
loadSource -sim_only -fileType {Verilog Header} -dir "$::DIR_PATH/RD53A_SIM_DAQ/src/verilog/array"
loadSource -sim_only -fileType {Verilog Header} -dir "$::DIR_PATH/RD53A_SIM_DAQ/src/verilog/array/cba"
loadSource -sim_only -fileType {Verilog Header} -dir "$::DIR_PATH/RD53A_SIM_DAQ/src/verilog/array/cba/components"
loadSource -sim_only -fileType {Verilog Header} -dir "$::DIR_PATH/RD53A_SIM_DAQ/src/verilog/array/interfaces"
loadSource -sim_only -fileType {Verilog Header} -dir "$::DIR_PATH/RD53A_SIM_DAQ/src/verilog/eoc"
loadSource -sim_only -fileType {Verilog Header} -dir "$::DIR_PATH/RD53A_SIM_DAQ/src/verilog/eoc/Aurora64b66b"
loadSource -sim_only -fileType {Verilog Header} -dir "$::DIR_PATH/RD53A_SIM_DAQ/src/verilog/eoc/autozeroing"
loadSource -sim_only -fileType {Verilog Header} -dir "$::DIR_PATH/RD53A_SIM_DAQ/src/verilog/eoc/cmd"
loadSource -sim_only -fileType {Verilog Header} -dir "$::DIR_PATH/RD53A_SIM_DAQ/src/verilog/eoc/gcr"
loadSource -sim_only -fileType {Verilog Header} -dir "$::DIR_PATH/RD53A_SIM_DAQ/src/verilog/eoc/jtag"
loadSource -sim_only -fileType {Verilog Header} -dir "$::DIR_PATH/RD53A_SIM_DAQ/src/verilog/eoc/mon"
loadSource -sim_only -fileType {Verilog Header} -dir "$::DIR_PATH/RD53A_SIM_DAQ/src/verilog/models"
loadSource -sim_only -fileType {Verilog Header} -dir "$::DIR_PATH/RD53A_SIM_DAQ/src/verilog/other"
loadSource -sim_only -fileType {Verilog Header} -dir "$::DIR_PATH/RD53A_SIM_DAQ/src/verilog/top"

# Fix the file type exceptions
set_property FILE_TYPE "VHDL 2008"   [get_files {regionDigitalWriter.vhd}]
set_property FILE_TYPE Verilog       [get_files {Serializer_TapDelayX4.v}]
set_property FILE_TYPE {Verilog Header} [get_files {RD53_AFE_BGPV.v}]

# Update messaging
set_msg_config -suppress -id {VRFC 10-2458}; # SIM: undeclared symbol, assumed default net type wire

# Setup the Verilog include paths and Verilog defines
set_property include_dirs "$::DIR_PATH/RD53A_SIM_DAQ $::DIR_PATH/RD53A_SIM_DAQ/src/verilog" [get_filesets sim_1]
set_property verilog_define TEST_DC=20 [get_filesets sim_1]

# Remove the .DCP and use the .XCI IP core instead 
remove_files [get_files {*.dcp}]
remove_files [get_files {DebugBridgeJtag.xci}]
remove_files [get_files {RD53_AFE_BGPV_inf.sv}]
remove_files [get_files {RD53_AFE_LBNL_inf.sv}]
remove_files [get_files {RD53_AFE_TO_inf.sv}]

# Set the top level synth_1 and sim_1
set_property top {SyncTrigRateVector} [get_filesets sources_1]
# set_property top {Rd53aTb} [get_filesets sim_1]
set_property top {example_tb} [get_filesets sim_1]
