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
    
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {U_HsioPgpLane/ClockManager7_1/MmcmGen.U_Mmcm/CLKOUT0}]] -group [get_clocks -of_objects [get_pins {U_HsioCore/U_RceG3Top/U_RceG3Clocks/U_MMCM/MmcmGen.U_Mmcm/CLKOUT0}]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {U_HsioPgpLane/ClockManager7_1/MmcmGen.U_Mmcm/CLKOUT0}]] -group [get_clocks -of_objects [get_pins {U_HsioCore/U_RceG3Top/U_RceG3Clocks/U_MMCM/MmcmGen.U_Mmcm/CLKOUT3}]]

set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {U_Hardware/U_Lane/U_PGPv3/REAL_PGP.GEN_LANE[0].U_Pgp/U_Pgp3Gtx7IpWrapper/U_RX_PLL/PllGen.U_Pll/CLKOUT0}]] -group [get_clocks -of_objects [get_pins {U_HsioCore/U_RceG3Top/U_RceG3Clocks/U_MMCM/MmcmGen.U_Mmcm/CLKOUT0}]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {U_Hardware/U_Lane/U_PGPv3/REAL_PGP.GEN_LANE[0].U_Pgp/U_Pgp3Gtx7IpWrapper/U_RX_PLL/PllGen.U_Pll/CLKOUT1}]] -group [get_clocks -of_objects [get_pins {U_HsioCore/U_RceG3Top/U_RceG3Clocks/U_MMCM/MmcmGen.U_Mmcm/CLKOUT3}]]

set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {U_Hardware/U_Lane/U_PGPv3/REAL_PGP.U_TX_PLL/PllGen.U_Pll/CLKOUT1}]] -group [get_clocks -of_objects [get_pins {U_HsioCore/U_RceG3Top/U_RceG3Clocks/U_MMCM/MmcmGen.U_Mmcm/CLKOUT0}]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {U_Hardware/U_Lane/U_PGPv3/REAL_PGP.U_TX_PLL/PllGen.U_Pll/CLKOUT1}]] -group [get_clocks -of_objects [get_pins {U_HsioCore/U_RceG3Top/U_RceG3Clocks/U_MMCM/MmcmGen.U_Mmcm/CLKOUT3}]]
