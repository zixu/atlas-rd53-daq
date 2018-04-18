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

import rogue
import rogue.hardware.axi

import pyrogue
import pyrogue.interfaces.simulation
import pyrogue.protocols

from surf.axi import *
from surf.xilinx import *
from surf.devices.micron import *
  
class Top(pyrogue.Device):
    def __init__(   self,       
            name        = "Top",
            description = "Container for FEB FPGA",
            dev         = '/dev/datadev_0',
            port        = 0,
            hwEmu       = False,
            **kwargs):
        super().__init__(name=name, description=description, **kwargs)
        
        ######################################################################
        
        # Create an empty data stream array
        self.dataStream = [None] * 4
        
        # Check if emulating the GUI interface
        if (hwEmu):
            # Create emulated hardware interface
            print ("Running in Hardware Emulation Mode:")
            memMap = pyrogue.interfaces.simulation.MemEmulate()
            
        else:
            ########################################################################################################################
            # https://github.com/slaclab/rogue/blob/master/include/rogue/hardware/axi/AxiStreamDma.h
            # static boost::shared_ptr<rogue::hardware::axi::AxiStreamDma> create (std::string path, uint32_t dest, bool ssiEnable);
            ########################################################################################################################
        
            # Connect the SRPv3 to QSFP[port].Lane[0].VC[1]
            srpStream  = rogue.hardware.axi.AxiStreamDma(dev,(128*port)+1,1)
            memMap = rogue.protocols.srp.SrpV3()                
            pr.streamConnectBiDir( memMap, srpStream )             
            
            # Create the Raw Data stream interface to QSFP[port].Lane[0].VC[0]
            self.dataStream[0] = rogue.hardware.axi.AxiStreamDma(dev,(128*port)+(32*0),1)
            
            # Create the Raw Data stream interface to QSFP[port].Lane[1].VC[0]
            self.dataStream[1] = rogue.hardware.axi.AxiStreamDma(dev,(128*port)+(32*1),1)
            
            # Create the Raw Data stream interface to QSFP[port].Lane[2].VC[0]
            self.dataStream[2] = rogue.hardware.axi.AxiStreamDma(dev,(128*port)+(32*2),1)
            
            # Create the Raw Data stream interface to QSFP[port].Lane[3].VC[0]
            self.dataStream[3] = rogue.hardware.axi.AxiStreamDma(dev,(128*port)+(32*3),1)            
            
        ######################################################################
            
        # Add devices
        self.add(AxiVersion(  memBase=memMap, offset=0x00000000))
        self.add(Xadc(        memBase=memMap, offset=0x00010000))
        self.add(AxiMicronP30(memBase=memMap, offset=0x00020000))
        