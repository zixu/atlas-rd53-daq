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

import pyrogue as pr

class TimingEmu(pr.Device):
    def __init__(   self,       
        name        = "Timing",
        description = "Container for TimingEmu FSM registers",
        ADDR_WIDTH_G = 8,
        **kwargs):
        
        super().__init__(name=name,description=description,**kwargs)

        self.add(pr.RemoteCommand(  
            name        = "OneShot",
            description = "One-shot trigger the FSM",
            offset      = 0x20000,
            bitSize     = 1,
            function    = lambda cmd: cmd.post(1),
        ))
     
        self.add(pr.RemoteVariable(
            name         = 'Continuous', 
            description  = 'continuous mode bit',
            offset       = 0x20004,
            bitSize      = 1, 
            mode         = 'RW',
        )) 
        
        self.add(pr.RemoteVariable(
            name         = 'MaxAddr', 
            description  = 'Max address used in the looping through the timing/trigger pattern LUTs',
            offset       = 0x20008,
            bitSize      = ADDR_WIDTH_G, 
            mode         = 'RW',
        )) 

        self.add(pr.RemoteVariable(
            name         = 'Iteration', 
            description  = 'Number of time to loop through the timing/trigger pattern LUTs',
            offset       = 0x2000C,
            bitSize      = 16, 
            mode         = 'RW',
        ))         
        
        self.addRemoteVariables(       
            name        = 'LutCalDat', 
            description = 'v.ttc.calDat     := ramData(0)(15 downto 0);', 
            offset      = 0x00000, 
            number      =  2**ADDR_WIDTH_G, 
            bitSize     =  16, 
            bitOffset   =  0, 
            stride      =  4,
            mode        = "RW", 
            hidden      = True,
        ) 

        self.addRemoteVariables(       
            name        = 'LutCalId', 
            description = 'v.ttc.calId      := ramData(0)(19 downto 16);', 
            offset      = 0x00000, 
            number      =  2**ADDR_WIDTH_G, 
            bitSize     =  4, 
            bitOffset   =  16, 
            stride      =  4,
            mode        = "RW", 
            hidden      = True,
        )

        self.addRemoteVariables(       
            name        = 'LutCal', 
            description = 'v.ttc.cal        := ramData(0)(20);', 
            offset      = 0x00000, 
            number      =  2**ADDR_WIDTH_G, 
            bitSize     =  1, 
            bitOffset   =  20, 
            stride      =  4,
            mode        = "RW", 
            hidden      = True,
        ) 

        self.addRemoteVariables(       
            name        = 'LutGPulseData', 
            description = 'v.ttc.gPulseData := ramData(1)(3 downto 0);', 
            offset      = 0x10000, 
            number      =  2**ADDR_WIDTH_G, 
            bitSize     =  4, 
            bitOffset   =  0, 
            stride      =  4,
            mode        = "RW", 
            hidden      = True,
        ) 

        self.addRemoteVariables(       
            name        = 'LutGPulseId', 
            description = 'v.ttc.gPulseId   := ramData(1)(7 downto 4);', 
            offset      = 0x10000, 
            number      =  2**ADDR_WIDTH_G, 
            bitSize     =  4, 
            bitOffset   =  4, 
            stride      =  4,
            mode        = "RW", 
            hidden      = True,
        )

        self.addRemoteVariables(       
            name        = 'LutGPulse', 
            description = 'v.ttc.gPulse     := ramData(1)(8);', 
            offset      = 0x10000, 
            number      =  2**ADDR_WIDTH_G, 
            bitSize     =  1, 
            bitOffset   =  8, 
            stride      =  4,
            mode        = "RW", 
            hidden      = True,
        ) 

        self.addRemoteVariables(       
            name        = 'LutBcr', 
            description = 'v.ttc.bcr        := ramData(1)(9);', 
            offset      = 0x10000, 
            number      =  2**ADDR_WIDTH_G, 
            bitSize     =  1, 
            bitOffset   =  9, 
            stride      =  4,
            mode        = "RW", 
            hidden      = True,
        )

        self.addRemoteVariables(       
            name        = 'LutEcr', 
            description = 'v.ttc.ecr        := ramData(1)(10);', 
            offset      = 0x10000, 
            number      =  2**ADDR_WIDTH_G, 
            bitSize     =  1, 
            bitOffset   =  10, 
            stride      =  4,
            mode        = "RW", 
            hidden      = True,
        )

        self.addRemoteVariables(       
            name        = 'LutTrig', 
            description = 'v.ttc.trig       := ramData(1)(11);', 
            offset      = 0x10000, 
            number      =  2**ADDR_WIDTH_G, 
            bitSize     =  1, 
            bitOffset   =  11, 
            stride      =  4,
            mode        = "RW", 
            hidden      = True,
        )  
        
class Timing(pr.Device):
    def __init__(   self,       
        name         = "Timing",
        description  = "Container for Timing/Trigger registers",
        **kwargs):
        
        super().__init__(name=name,description=description,**kwargs)

        self.add(TimingEmu(      
            name         = 'TimingEmu', 
            offset       = 0x00000000, 
            expand       = False,
            ADDR_WIDTH_G = 8,
        ))        
      