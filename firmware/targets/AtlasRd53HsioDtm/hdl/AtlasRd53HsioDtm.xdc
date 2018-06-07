##############################################################################
## This file is part of 'ATLAS RD53 DEV'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'ATLAS RD53 DEV', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################

# PGPv3 to FEB
set_property PACKAGE_PIN W2 [get_ports dtmToSfpHsP]
set_property PACKAGE_PIN W1 [get_ports dtmToSfpHsM]
set_property PACKAGE_PIN V4 [get_ports sfpToDtmHsP]
set_property PACKAGE_PIN V3 [get_ports sfpToDtmHsM]

# PGPv2b to HSIO Artix-7 FPGA
set_property PACKAGE_PIN AB4 [get_ports dtmToFpgaHsP]
set_property PACKAGE_PIN AB3 [get_ports dtmToFpgaHsM]
set_property PACKAGE_PIN AA6 [get_ports fpgaToDtmHsP]
set_property PACKAGE_PIN AA5 [get_ports fpgaToDtmHsM]

create_clock -name locRefClk -period 4.0 [get_ports locRefClk1P]
    
set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks sysClk200] \
    -group [get_clocks -include_generated_clocks sysClk125] \
    -group [get_clocks -include_generated_clocks -of_objects [get_pins -hier -filter {name=~*gt0_Pgp3Gtx7Ip6G_i*gtxe2_i*TXOUTCLK}]] \
    -group [get_clocks -include_generated_clocks -of_objects [get_pins -hier -filter {name=~*gt0_Pgp3Gtx7Ip6G_i*gtxe2_i*RXOUTCLK}]]
    
set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks sysClk200] \
    -group [get_clocks -include_generated_clocks sysClk125] \
    -group [get_clocks -include_generated_clocks locRefClk]
