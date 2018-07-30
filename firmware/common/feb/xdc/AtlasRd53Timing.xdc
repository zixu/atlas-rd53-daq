##############################################################################
## This file is part of 'ATLAS RD53 DEV'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'ATLAS RD53 DEV', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################

create_clock -name pgpClkP       -period 3.200 [get_ports {pgpClkP}]
create_clock -name intClk160MHz  -period 6.237 [get_ports {intClk160MHzP}]
create_clock -name extClk160MHz0 -period 6.237 [get_ports {extClk160MHzP[0]}]
create_clock -name extClk160MHz1 -period 6.237 [get_ports {extClk160MHzP[1]}]

create_generated_clock -name iprogClk  [get_pins {U_Core/U_System/U_AxiVersion/GEN_ICAP.Iprog_1/GEN_7SERIES.Iprog7Series_Inst/DIVCLK_GEN.BUFR_ICPAPE2/O}] 
create_generated_clock -name dnaClk    [get_pins {U_Core/U_System/U_AxiVersion/GEN_DEVICE_DNA.DeviceDna_1/GEN_7SERIES.DeviceDna7Series_Inst/BUFR_Inst/O}] 
create_generated_clock -name dnaClkInv [get_pins {U_Core/U_System/U_AxiVersion/GEN_DEVICE_DNA.DeviceDna_1/GEN_7SERIES.DeviceDna7Series_Inst/DNA_CLK_INV_BUFR/O}] 

set_clock_groups -asynchronous \ 
   -group [get_clocks -include_generated_clocks {pgpClkP}] \
   -group [get_clocks -include_generated_clocks {intClk160MHz}] \
   -group [get_clocks -include_generated_clocks {extClk160MHz0}] \
   -group [get_clocks -include_generated_clocks {extClk160MHz1}]
    
set_case_analysis 1 [get_pins {U_Core/U_Clk/U_BUFGMUX_0/S}]
set_case_analysis 1 [get_pins {U_Core/U_Clk/U_BUFGMUX_1/S}]    

# set_property IODELAY_GROUP xapp_idelay [get_cells U_Core/U_IDELAYCTRL]
# set_property IODELAY_GROUP xapp_idelay [get_cells U_Core/GEN_VEC[*].U_RxPhy/U_RxPhy/U_RxPhyLayer/GEN_LANE[*].U_Rx/custom_serdes.IDELAYE2_inst]