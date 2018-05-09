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

class SysReg(pr.Device):
    def __init__(   
        self,       
        name        = "SysReg",
        description = "Container for system registers",
        pollInterval = 1,
            **kwargs):
        
        super().__init__(
            name        = name,
            description = description,
            **kwargs)
            
        self.add(pr.RemoteVariable(
            name         = 'IdlyCtrlRdyCnt', 
            description  = 'IDELAY controller ready counter',
            offset       = 0x0,
            bitSize      = 32, 
            mode         = 'RO',
            base         = pr.UInt,
            pollInterval = pollInterval,
        )) 
        
        self.add(pr.RemoteVariable(
            name         = 'PllLockedCnt', 
            description  = 'PLL Locked counter',
            offset       = 0x4,
            bitSize      = 32, 
            mode         = 'RO',
            base         = pr.UInt,
            pollInterval = pollInterval,
        ))            
            
        self.add(pr.RemoteVariable(
            name         = 'IdlyCtrlRdy', 
            description  = 'IDELAY controller ready status',
            offset       = 0x400,
            bitSize      = 1,
            bitOffset    = 0,             
            mode         = 'RO',
            base         = pr.UInt,
            pollInterval = pollInterval,
        )) 
        
        self.add(pr.RemoteVariable(
            name         = 'PllLocked', 
            description  = 'PLL Locked status',
            offset       = 0x400,
            bitSize      = 1,
            bitOffset    = 1,  
            mode         = 'RO',
            base         = pr.UInt,
            pollInterval = pollInterval,
        ))         
            
        self.add(pr.RemoteVariable(
            name         = 'RefClk160MHzFreq', 
            description  = 'Reference Clock Frequency',
            offset       = 0x404,
            bitSize      = 32, 
            mode         = 'RO',
            units        = "Hz", 
            disp         = '{:d}',
            base         = pr.UInt,
            pollInterval = pollInterval,
        ))

        self.add(pr.RemoteCommand(   
            name         = 'SoftTrig',
            description  = 'Software Trigger',
            offset       = 0x800,
            bitSize      = 1,
            base         = pr.UInt,
            function     = lambda cmd: cmd.toggle(1),
            hidden       = False,
        ))
        
        self.add(pr.RemoteCommand(   
            name         = 'SoftRst',
            description  = 'SoftReset',
            offset       = 0x804,
            bitSize      = 1,
            base         = pr.UInt,
            function     = lambda cmd: cmd.toggle(1),
            hidden       = False,
        ))

        self.add(pr.RemoteCommand(   
            name         = 'HardRst',
            description  = 'HardReset',
            offset       = 0x808,
            bitSize      = 1,
            base         = pr.UInt,
            function     = lambda cmd: cmd.toggle(1),
            hidden       = False,
        ))

        self.add(pr.RemoteCommand(   
            name         = 'PllRst',
            description  = 'PLL Reset',
            offset       = 0x80C,
            bitSize      = 1,
            base         = pr.UInt,
            function     = lambda cmd: cmd.toggle(1),
            hidden       = False,
        ))        

        self.add(pr.RemoteVariable(
            name         = 'RefClkSel', 
            description  = 'Reference Clock Select',
            offset       = 0x810,
            bitSize      = 2, 
            mode         = 'RW',
            enum         = {
                0x0: 'IntClk', 
                0x2: 'ExtSmaClk', 
                0x3: 'ExtLemoClk',
            },
        ))

        self.add(pr.RemoteVariable(
            name         = 'RollOverEn', 
            description  = 'Rollover enable for status counters',
            offset       = 0xFF8,
            bitSize      = 2, 
            mode         = 'RW',
            base         = pr.UInt,
        ))        
        
        self.add(pr.RemoteCommand(   
            name         = 'CntRst',
            description  = 'Status counter reset',
            offset       = 0xFFC,
            bitSize      = 1,
            bitOffset    = 0x00,
            base         = pr.UInt,
            function     = lambda cmd: cmd.post(1),
            hidden       = False,
        ))        
            
class Ntc(pr.Device):
    def __init__(   
        self,       
        name        = "Ntc",
        description = "Container for MAX6682 SPI modules",
            **kwargs):
        
        super().__init__(
            name        = name,
            description = description,
            **kwargs)
            
        for i in range(4):

            self.add(pr.RemoteVariable(  
                name        = ('Dout[%d]' % i),
                description = 'Max6682 Data output',
                offset      = (4*i), 
                bitSize     = 11,  
                base        = pr.UInt,
                mode        = 'RO',
                pollInterval = 5,
            )) 

            # self.add(pr.LinkVariable(
                # name         = ('Temp[%d]' % i), 
                # mode         = 'RO', 
                # units        = 'degC',
                # linkedGet    = self.convTemp,
                # disp         = '{:1.3f}',
                # dependencies = [self.variables[('Dout[%d]' % i)]],
            # ))            
        
    # @staticmethod
    # def convTemp(dev, var):
        # ##########################################################################
        # # Based on 6th order polynomial fit of Table 1
        # # y = -2E-13x6 + 2E-09x5 - 5E-06x4 + 0.0082x3 - 7.448x2 + 3606.4x - 723443
        # ##########################################################################
        # x  = var.dependencies[0].value()
        # x ^= 0x400 # Convert to binary with offset
        # x  = float(x)        
        # return (-2.0E-13*(x**6) + 2.0E-09*(x**5) - 5.0E-06*(x**4) + 0.0082*(x**3) - 7.448*(x**2) + 3606.4*(x**1) - 723443.0*(x**0))
        
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
        
        self.add(SysReg(
            name        = 'SysReg', 
            description = 'This device contains system level configuration and status registers', 
            memBase     = memMap, 
            offset      = 0x00030000, 
            expand      = False,
        ))
        
        self.add(Ntc(
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
        