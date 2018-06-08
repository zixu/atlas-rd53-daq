#!/usr/bin/env python3
#-----------------------------------------------------------------------------
# Title      : GUI Client
#-----------------------------------------------------------------------------
# File       : guiClient.py
# Created    : 2016-09-29
#-----------------------------------------------------------------------------
# Description:
# Generic GUI client for rogue
#-----------------------------------------------------------------------------
# This file is part of the rogue_example software. It is subject to 
# the license terms in the LICENSE.txt file found in the top-level directory 
# of this distribution and at: 
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
# No part of the rogue_example software, including this file, may be 
# copied, modified, propagated, or distributed except according to the terms 
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------
import pyrogue.gui
import getopt
import sys
import argparse

# Set the argument parser
parser = argparse.ArgumentParser()

# Add arguments
parser.add_argument(
    "--cltIp", 
    type     = str,
    required = True,
    help     = "Client (Local) IP address",
) 

parser.add_argument(
    "--srvIp", 
    type     = str,
    required = True,
    help     = "Server (RCE) IP address",
) 

# Get the arguments
args = parser.parse_args()

# Set host= to the address of a network interface to secificy the network to use
# Set ns= to the address of the nameserver(optional)
client = pyrogue.PyroClient(
    group     = 'rce', 
    localAddr = args.cltIp, # Local IP
    nsAddr    = args.srvIp, # RCE IP
) 

# Create GUI
appTop = pyrogue.gui.application(sys.argv)
guiTop = pyrogue.gui.GuiTop(group='rootMesh')
appTop.setStyle('Fusion')
guiTop.addTree(client.getRoot(name='rceServer'))
guiTop.resize(600, 800)

print("Starting GUI...\n");

# Run gui
appTop.exec_()

client.stop()

