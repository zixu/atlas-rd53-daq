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
import pyrogue as pr
import pyrogue.gui
import PyQt4.QtGui
import argparse
import common as feb

#################################################################

# Set the argument parser
parser = argparse.ArgumentParser()

# Convert str to bool
argBool = lambda s: s.lower() in ['true', 't', 'yes', '1']

# Add arguments
parser.add_argument(
    "--dev", 
    type     = str,
    required = False,
    default  = '/dev/datadev_0',
    help     = "path to device",
)  

parser.add_argument(
    "--port", 
    type     = int,
    required = False,
    default  = 0,
    help     = "KCU1500 QSFP port Number (0 or 1)",
)  

parser.add_argument(
    "--hwEmu", 
    type     = argBool,
    required = False,
    default  = False,
    help     = "hardware emulation (false=normal operation, true=emulation)",
)  

parser.add_argument(
    "--pollEn", 
    type     = argBool,
    required = False,
    default  = True,
    help     = "Enable auto-polling",
) 

parser.add_argument(
    "--initRead", 
    type     = argBool,
    required = False,
    default  = True,
    help     = "Enable read all variables at start",
)  

parser.add_argument(
    "--guiType", 
    type     = str,
    required = False,
    default  = 'feb',
    help     = "GUI Type: feb or pcie",
)  

# Get the arguments
args = parser.parse_args()

#################################################################

# Set base
base = pr.Root(name='base',description='')    

# Add Base Device
if ( args.guiType == 'feb' ):
    base.add(feb.Top(
        dev   = args.dev,
        port  = args.port,
        hwEmu = args.hwEmu,
    ))
    
elif (  args.guiType == 'pcie' ):
    base.add(feb.Pcie(
        dev   = args.dev,
        hwEmu = args.hwEmu,
    ))
    
else:
    raise ValueError("Invalid guiType type (%s): must be feb or pcie" % ( args.guiType) )  

# Start the system
base.start(
    pollEn   = args.pollEn,
    initRead = args.initRead,
)

# Create GUI
appTop = PyQt4.QtGui.QApplication(sys.argv)
appTop.setStyle('Fusion')
guiTop = pyrogue.gui.GuiTop(group='rootMesh')
guiTop.addTree(base)
guiTop.resize(800, 1000)

print("Starting GUI...\n");

# Run GUI
appTop.exec_()    
    
# Close
base.stop()
exit()   