# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

loadIpCore -path "$::DIR_PATH/aurora_rx/hdl/ip_cores/fifo_fwft/fifo_fwft.xci"

# loadSource -dir  "$::DIR_PATH/aurora_rx/hdl/rx_core"

loadSource -path  "$::DIR_PATH/aurora_rx/hdl/rx_core/aurora_rx_four_lane_top.sv"
loadSource -path  "$::DIR_PATH/aurora_rx/hdl/rx_core/aurora_rx_top.sv"
loadSource -path  "$::DIR_PATH/aurora_rx/hdl/rx_core/aurora_rx_top_xapp.sv"
loadSource -path  "$::DIR_PATH/aurora_rx/hdl/rx_core/ber.sv"
loadSource -path  "$::DIR_PATH/aurora_rx/hdl/rx_core/ber_scrambler.v"
loadSource -path  "$::DIR_PATH/aurora_rx/hdl/rx_core/bitslip_fsm.sv"
loadSource -path  "$::DIR_PATH/aurora_rx/hdl/rx_core/block_sync.v"
loadSource -path  "$::DIR_PATH/aurora_rx/hdl/rx_core/channel_bond.sv"
loadSource -path  "$::DIR_PATH/aurora_rx/hdl/rx_core/delay_controller_wrap.v"
loadSource -path  "$::DIR_PATH/aurora_rx/hdl/rx_core/descrambler.v"

# loadSource -path  "$::DIR_PATH/aurora_rx/hdl/rx_core/gearbox_32_to_66.v"
loadSource -path  "$::DIR_PATH/bug-fix/gearbox_32_to_66.v"

loadSource -path  "$::DIR_PATH/aurora_rx/hdl/rx_core/io_buf_config_driver.sv"
loadSource -path  "$::DIR_PATH/aurora_rx/hdl/rx_core/lcd_driver.vhd"
loadSource -path  "$::DIR_PATH/aurora_rx/hdl/rx_core/serdes_1_to_468_idelay_ddr.v"
