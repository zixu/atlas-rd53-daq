##############################################################################
## This file is part of 'ATLAS RD53 DEV'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'ATLAS RD53 DEV', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################

create_generated_clock -name clk300    [get_pins {U_Core/GEN_ETH.U_ETH/U_MMCM/MmcmGen.U_Mmcm/CLKOUT0}] 
create_generated_clock -name clk156    [get_pins {U_Core/GEN_ETH.U_ETH/U_MMCM/MmcmGen.U_Mmcm/CLKOUT1}] 

set_clock_groups -asynchronous -group [get_clocks {pgpClkP}] -group [get_clocks -of_objects [get_pins U_Core/GEN_ETH.U_ETH/GEN_1G.U_Eth/U_MMCM/MmcmGen.U_Mmcm/CLKOUT0]]
set_clock_groups -asynchronous -group [get_clocks {clk156}]  -group [get_clocks -of_objects [get_pins U_Core/GEN_ETH.U_ETH/GEN_1G.U_Eth/U_MMCM/MmcmGen.U_Mmcm/CLKOUT0]]

set_clock_groups -asynchronous -group [get_clocks {clk156}] -group [get_clocks {iprogClk}]
set_clock_groups -asynchronous -group [get_clocks {clk156}] -group [get_clocks {dnaClk}]  -group [get_clocks {dnaClkInv}] 
