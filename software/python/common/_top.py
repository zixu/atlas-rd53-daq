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
import pyrogue as pr
import pyrogue.interfaces.simulation
import pyrogue.protocols

import surf.axi as axiVer
import surf.xilinx as xil
import surf.devices.micron as prom
import surf.devices.linear as linear
import surf.devices.nxp as nxp

import common
        
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
        self.cmdStream  = [None] * 4
        
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
        
            # Connect the SRPv3 to QSFP[port].Lane[0].VC[0]
            srpStream  = rogue.hardware.axi.AxiStreamDma(dev,(128*port)+0,1)
            memMap = rogue.protocols.srp.SrpV3()                
            pr.streamConnectBiDir( memMap, srpStream )             
            
            # Create the TLU stream interface to QSFP[port].Lane[0].VC[1]
            self.tluStream = rogue.hardware.axi.AxiStreamDma(dev,(128*port)+1,1)            
            
            for i in range(4):
                # Create the RD53 Data stream interface to QSFP[port].Lane[0].VC[2+i]
                self.dataStream[i] = rogue.hardware.axi.AxiStreamDma(dev,(128*port)+2+i,1)
                
                # Create the RD53 CMD stream interface to QSFP[port].Lane[0].VC[2+i]
                self.cmdStream[i] = rogue.hardware.axi.AxiStreamDma(dev,(128*port)+6+i,1)                
                       
        ######################################################################
            
        # Add devices
        self.add(axiVer.AxiVersion( 
            name    = 'AxiVersion', 
            memBase = memMap, 
            offset  = 0x00000000, 
            expand  = False,
        ))
        
        self.add(xil.Xadc(
            name    = 'Xadc', 
            memBase = memMap,
            offset  = 0x00010000, 
            expand  = False,
        ))
        
        self.add(prom.AxiMicronP30(
            name    = 'AxiMicronP30', 
            memBase = memMap, 
            offset  = 0x00020000, 
            hidden  = True, # Hidden in GUI because indented for scripting
        ))
        
        self.add(common.SysReg(
            name        = 'SysReg', 
            description = 'This device contains system level configuration and status registers', 
            memBase     = memMap, 
            offset      = 0x00030000, 
            expand      = False,
        ))
        
        self.add(common.Ntc(
            name        = 'Rd53Ntc', 
            description = 'This device contains the four NTC MAX6682 readout modules', 
            memBase     = memMap, 
            offset      = 0x00040000, 
            expand      = False,
        ))
        
        self.add(nxp.Sa56004x(      
            name        = 'BoardTemp', 
            description = 'This device monitors the board temperature and FPGA junction temperature', 
            memBase     = memMap, 
            offset      = 0x00050000, 
            expand      = False,
        ))
        
        self.add(linear.Ltc4151(
            name        = 'BoardPwr', 
            description = 'This device monitors the board power, input voltage and input current', 
            memBase     = memMap, 
            offset      = 0x00050400, 
            senseRes    = 20.E-3, # Units of Ohms
            expand      = False,
        ))
        
        for i in range(4):
            self.add(common.Dport(
                name        = ('Dport[%d]'%i), 
                description = 'This device contains all the registers for a DPORT pair', 
                memBase     = memMap, 
                offset      = (0x01000000*(i+1)), 
                expand      = False,
            ))            
