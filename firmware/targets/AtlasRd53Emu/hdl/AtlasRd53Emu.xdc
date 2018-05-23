##############################################################################
## This file is part of 'ATLAS RD53 DEV'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'ATLAS RD53 DEV', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################

create_clock -name refClk0 -period 24.950 [get_ports {dPortAuxP[0]}]
create_clock -name refClk1 -period 24.950 [get_ports {dPortAuxP[1]}]
create_clock -name refClk2 -period 24.950 [get_ports {dPortAuxP[2]}]
create_clock -name refClk3 -period 24.950 [get_ports {dPortAuxP[3]}]

# Not ideal but work around to not having dPortAuxP/N on global clock ports
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets U_Core/GEN_EMU[0].U_Dport/refClk]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets U_Core/GEN_EMU[1].U_Dport/refClk]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets U_Core/GEN_EMU[2].U_Dport/refClk]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets U_Core/GEN_EMU[3].U_Dport/refClk]

