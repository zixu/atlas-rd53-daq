#!/usr/bin/env python3
#-----------------------------------------------------------------------------
# This file is part of the 'Development Board Examples'. It is subject to 
# the license terms in the LICENSE.txt file found in the top-level directory 
# of this distribution and at: 
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
# No part of the 'Development Board Examples', including this file, may be 
# copied, modified, propagated, or distributed except according to the terms 
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------

import sys
import pyrogue as pr
import common as feb
import sys
import time
import socket
import rogue
import argparse

#rogue.Logging.setLevel(rogue.Logging.Warning)

#################################################################

# Set the argument parser
parser = argparse.ArgumentParser()

# Convert str to bool
argBool = lambda s: s.lower() in ['true', 't', 'yes', '1']

# Add arguments
parser.add_argument(
    "--hwType", 
    type     = str,
    required = False,
    default  = 'hsio-dtm',
    help     = "either hsio-dtm or rce-dpm",
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

# Get the arguments
args = parser.parse_args()

#################################################################

# Set base
base = feb.Top(name='rceServer',dev='/dev/axi_stream_dma_2',hwType=args.hwType)  

# Start the system
base.start(
    pollEn    = args.pollEn,
    initRead  = args.initRead,
    pyroGroup = 'rce', 
    pyroAddr  = socket.gethostbyname(socket.gethostname()), # RCE IP  
    timeout   = 1.0,
)

# Close window and stop polling
def stop():
    base.stop()
    exit()

# Start with ipython -i scripts/rceGuiClient.py
print("Started rogue mesh server. To exit type stop()")

while True:
    time.sleep(1)
    
