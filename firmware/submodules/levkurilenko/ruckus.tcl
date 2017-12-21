# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

loadSource -dir  "$::DIR_PATH/aurora_rx/hdl/rx_core"
loadIpCore -path "$::DIR_PATH/aurora_rx/hdl/ip_cores/fifo_fwft/fifo_fwft.xci"
