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
import sys
import time
import socket
import argparse

import rogue
import rogue.hardware.axi
import pyrogue.utilities.prbs

import RceG3 as rceg3
import surf.protocols.pgp as pgp

rogue.Logging.setLevel(rogue.Logging.Warning)

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
    default  = '/dev/axi_stream_dma_1',
    help     = "path to device",
)  

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

# Set the DMA loopback channel
vcPrbs = rogue.hardware.axi.AxiStreamDma(args.dev,0,1)

# Set base
base = pr.Root(name='rceServer',description='DPM Loopback Testing')

prbsRx = pyrogue.utilities.prbs.PrbsRx(name='PrbsRx')
pyrogue.streamConnect(vcPrbs,prbsRx)
base.add(prbsRx)  
    
prbTx = pyrogue.utilities.prbs.PrbsTx(name="PrbsTx")
pyrogue.streamConnect(prbTx, vcPrbs)
base.add(prbTx)  

#################################################################

# Create the mmap interface
rceMap = rogue.hardware.axi.AxiMemMap('/dev/rce_memmap')

# Add RCE version device
base.add(rceg3.RceVersion( 
    memBase = rceMap,
    expand  = False,
))  

# Add PGPv3 to the FEB
base.add(pgp.Pgp3AxiL( 
    name    = 'Pgp3Mon',
    memBase = rceMap,
    offset  = 0xA0000000,
    numVc   = 1,
    writeEn = True,
    expand  = False,
)) 

# Check for HSIO DTM
if ( args.hwType == 'hsio-dtm' ):
    # Add PGPv2b to the HSIO FPGA
    base.add(pgp.Pgp2bAxi( 
        name    = 'Pgp2bMon',
        memBase = rceMap,
        offset  = 0xA1000000,
        expand  = False,
    ))    

#################################################################

# Start the system
base.start(
    pollEn    = args.pollEn,
    initRead  = args.initRead,
    pyroGroup = 'rce', 
    pyroAddr  = socket.gethostbyname(socket.gethostname()), # RCE IP   
)

# Close window and stop polling
def stop():
    base.stop()
    exit()

# Start with ipython -i scripts/rceGuiClient.py
print("Started rogue mesh server. To exit type stop()")

while True:
    time.sleep(1)
    
