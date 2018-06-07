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
import rogue
import rogue.hardware.axi
import pyrogue.utilities.prbs

rogue.Logging.setLevel(rogue.Logging.Warning)

# Set the DMA loopback channel
vcPrbs = rogue.hardware.axi.AxiStreamDma("/dev/axi_stream_dma_1",0,1)

# Set base
base = pr.Root(name='rceServer',description='DPM Loopback Testing')

prbsRx = pyrogue.utilities.prbs.PrbsRx(name='PrbsRx')
pyrogue.streamConnect(vcPrbs,prbsRx)
base.add(prbsRx)  
    
prbTx = pyrogue.utilities.prbs.PrbsTx(name="PrbsTx")
pyrogue.streamConnect(prbTx, vcPrbs)
base.add(prbTx)  

# Start the system
base.start(
    pollEn    = True,
    initRead  = True,
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
    
