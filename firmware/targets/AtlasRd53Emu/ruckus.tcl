# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load common and sub-module
loadRuckusTcl $::env(PROJ_DIR)/../../submodules/surf
loadRuckusTcl $::env(PROJ_DIR)/../../common/feb

# Load levkurilenko bitbucket source code
loadSource -dir "$::env(PROJ_DIR)/../../submodules/levkurilenko/cern_work/RD53_emulator/src/on_chip"
loadIpCore -dir "$::env(PROJ_DIR)/../../submodules/levkurilenko/cern_work/RD53_emulator/RD53_Emulator/RD53_Emulation.srcs/sources_1/ip/cmd_oserdes"
loadIpCore -dir "$::env(PROJ_DIR)/../../submodules/levkurilenko/cern_work/RD53_emulator/RD53_Emulator/RD53_Emulation.srcs/sources_1/ip/fifo_generator_0"
loadIpCore -dir "$::env(PROJ_DIR)/../../submodules/levkurilenko/cern_work/RD53_emulator/RD53_Emulator/RD53_Emulation.srcs/sources_1/ip/fifo_generator_1"
loadIpCore -dir "$::env(PROJ_DIR)/../../submodules/levkurilenko/cern_work/RD53_emulator/RD53_Emulator/RD53_Emulation.srcs/sources_1/ip/fifo_generator_2"
loadIpCore -dir "$::env(PROJ_DIR)/../../submodules/levkurilenko/cern_work/RD53_emulator/RD53_Emulator/RD53_Emulation.srcs/sources_1/ip/hitDataFIFO"
loadIpCore -dir "$::env(PROJ_DIR)/../../submodules/levkurilenko/cern_work/RD53_emulator/RD53_Emulator/RD53_Emulation.srcs/sources_1/ip/triggerFifo"

# Load local source Code
loadSource      -dir  "$::DIR_PATH/hdl"
loadConstraints -dir  "$::DIR_PATH/hdl"

# Remove unused files with broken syntax
remove_files [get_files Commands.sv]