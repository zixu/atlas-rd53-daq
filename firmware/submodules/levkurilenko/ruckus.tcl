# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

loadIpCore -path "$::DIR_PATH/aurora_rx/hdl/ip_cores/fifo_fwft.xcix"
loadSource -dir  "$::DIR_PATH/aurora_rx/hdl/rx_core"
