##############################################################################
## This file is part of 'DUNE Development Firmware'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'DUNE Development Firmware', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################

# set_property DIFF_TERM true [get_ports {dtmRefClkP}]
# set_property DIFF_TERM true [get_ports {dtmClkM[*]}]

create_clock -name locRefClk -period 4.0 [get_ports locRefClkP]
