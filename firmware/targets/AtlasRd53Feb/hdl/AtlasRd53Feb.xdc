##############################################################################
## This file is part of 'ATLAS RD53 DEV'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'ATLAS RD53 DEV', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################

create_generated_clock -name clk640    [get_pins {U_Core/U_Clk/U_PLL/PllGen.U_Pll/CLKOUT0}] 
create_generated_clock -name clk160    [get_pins {U_Core/U_Clk/U_PLL/PllGen.U_Pll/CLKOUT1}] 
create_generated_clock -name clk40     [get_pins {U_Core/U_Clk/U_PLL/PllGen.U_Pll/CLKOUT2}] 

set_clock_groups -asynchronous \ 
   -group [get_clocks -include_generated_clocks {pgpClkP}] \
   -group [get_clocks -include_generated_clocks {intClk160MHz}] \
   -group [get_clocks -include_generated_clocks {extClk160MHz0}] \
   -group [get_clocks -include_generated_clocks {extClk160MHz1}]
    
set_case_analysis 1 [get_pins {U_Core/U_Clk/U_BUFGMUX_0/S}]
set_case_analysis 1 [get_pins {U_Core/U_Clk/U_BUFGMUX_1/S}]
