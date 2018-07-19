#!/usr/bin/env python3
##############################################################################
## This file is part of 'ATLAS RD53 DEV'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'ATLAS RD53 DEV', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################

import sys
import rogue
import pyrogue
import pyrogue as pr
import pyrogue.gui
import pyrogue.utilities.prbs
import pyrogue.interfaces.simulation

rogue.Logging.setLevel(rogue.Logging.Warning)
# rogue.Logging.setFilter("pyrogue.interfaces.simulation.StreamSim",rogue.Logging.Info)
rogue.Logging.setLevel(rogue.Logging.Debug)

#################################################################

base = pr.Root(name='simulation',description='')

vcPrbs = pr.interfaces.simulation.StreamSim(host='localhost', dest=0, uid=1, ssi=True)

prbsRx = pyrogue.utilities.prbs.PrbsRx(name='PrbsRx')
pyrogue.streamConnect(vcPrbs,prbsRx)
base.add(prbsRx)  
    
prbTx = pyrogue.utilities.prbs.PrbsTx(name="PrbsTx")
pyrogue.streamConnect(prbTx, vcPrbs)
base.add(prbTx) 

# Start the system
base.start()

# Create GUI
appTop = pr.gui.application(sys.argv)
guiTop = pr.gui.GuiTop(group='rootMesh')
appTop.setStyle('Fusion')
guiTop.addTree(base)
guiTop.resize(600, 800)

print("Starting GUI...\n");

# Run GUI
appTop.exec_()    
    
# Close
base.stop()
exit()   
