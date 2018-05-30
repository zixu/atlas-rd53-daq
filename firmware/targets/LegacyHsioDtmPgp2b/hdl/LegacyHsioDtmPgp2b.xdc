##############################################################################
## This file is part of 'ATLAS RD53 DEV'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'ATLAS RD53 DEV', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################

#SFP
#set_property PACKAGE_PIN W2 [get_ports dtmToRtmHsP]
#set_property PACKAGE_PIN W1 [get_ports dtmToRtmHsM]
#set_property PACKAGE_PIN V4 [get_ports rtmToDtmHsP]
#set_property PACKAGE_PIN V3 [get_ports rtmToDtmHsM]
#HSIO traces
set_property PACKAGE_PIN AB4 [get_ports dtmToRtmHsP]
set_property PACKAGE_PIN AB3 [get_ports dtmToRtmHsM]
set_property PACKAGE_PIN AA6 [get_ports rtmToDtmHsP]
set_property PACKAGE_PIN AA5 [get_ports rtmToDtmHsM]

# IO Types
#set_property IOSTANDARD LVDS_25  [get_ports dtmToRtmLsP]
#set_property IOSTANDARD LVDS_25  [get_ports dtmToRtmLsM]
#set_property IOSTANDARD LVCMOS25 [get_ports plSpareP]
#set_property IOSTANDARD LVCMOS25 [get_ports plSpareM]

# PGP Clocks
create_clock -name locRefClk -period 4.0 [get_ports locRefClkP]

#create_generated_clock -name pgpClk250 -source [get_ports locRefClkP] \
##    -multiply_by 5 -divide_by 8 [get_pins U_HsioPgpLane/U_PgpClkGen/CLKOUT0]
create_generated_clock -name pgpClk -source [get_ports locRefClkP] \
    -multiply_by 5 -divide_by 8 [get_pins U_HsioPgpLane/ClockManager7_1/MmcmGen.U_Mmcm/CLKOUT0]

set_clock_groups -asynchronous \
      -group [get_clocks -include_generated_clocks fclk0] \
      -group [get_clocks -include_generated_clocks locRefClk]

set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_HsioCore/U_RceG3Top/U_RceG3AxiCntl/U_DeviceDna/GEN_7SERIES.DeviceDna7Series_Inst/DNA_CLK_INV_BUFR/O]] -group [get_clocks sysClk125]
set_clock_groups -asynchronous -group [get_clocks dnaClk] -group [get_clocks -of_objects [get_pins U_HsioCore/U_RceG3Top/U_RceG3AxiCntl/U_DeviceDna/GEN_7SERIES.DeviceDna7Series_Inst/DNA_CLK_INV_BUFR/O]]
