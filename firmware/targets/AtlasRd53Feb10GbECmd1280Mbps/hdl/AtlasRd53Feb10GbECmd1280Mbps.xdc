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

create_generated_clock  -name ethClk    [get_pins {U_Core/GEN_ETH.U_ETH/GEN_10G.U_Eth/TenGigEthGtx7Clk_Inst/IBUFDS_GTE2_Inst/ODIV2}] 

set_clock_groups -asynchronous -group [get_clocks {ethClk}] -group [get_clocks {U_Core/GEN_ETH.U_ETH/GEN_10G.U_Eth/GEN_LANE[0].TenGigEthGtx7_Inst/U_TenGigEthGtx7Core/U0/gt0_gtwizard_10gbaser_multi_gt_i/gt0_gtwizard_10gbaser_i/gtxe2_i/TXOUTCLK}]                               

set_clock_groups -asynchronous -group [get_clocks {clk156}] -group [get_clocks {ethClk}]
set_clock_groups -asynchronous -group [get_clocks {clk156}] -group [get_clocks {iprogClk}]
set_clock_groups -asynchronous -group [get_clocks {clk156}] -group [get_clocks {dnaClk}]  -group [get_clocks {dnaClkInv}] 
