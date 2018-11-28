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
            offset      = 0x00,
            bitSize     = 1,
            function    = lambda cmd: cmd.post(1),
        ))
     
        self.add(pr.RemoteVariable(
            name         = 'TimerSize', 
            description  = 'Sets the timer\'s timeout configuration size between iterations',
            offset       = 0x04,
            bitSize      = 32, 
            mode         = 'RW',
            units        = '1/160MHz',
        ))  
        
        self.add(pr.RemoteVariable(
            name         = 'MaxAddr', 
            description  = 'Max address used in the looping through the timing/trigger pattern LUTs',
            offset       = 0x08,
            bitSize      = ADDR_WIDTH_G, 
            mode         = 'RW',
        )) 

        self.add(pr.RemoteVariable(
            name         = 'Iteration', 
            description  = 'Number of time to loop through the timing/trigger pattern LUTs',
            offset       = 0x0C,
            bitSize      = 16, 
            mode         = 'RW',
        ))  

        self.add(pr.RemoteVariable(
            name         = 'BackPreasureCnt', 
            description  = 'Increments when back pressure detected during AXIS streaming',
            offset       = 0x10,
            bitSize      = 32, 
            mode         = 'RO',
        ))          
        
class Timing(pr.Device):
    def __init__(   self,       
        name         = "Timing",
        description  = "Container for TLU registers",
        ADDR_WIDTH_G = 8,
        **kwargs):
        
        super().__init__(name=name,description=description,**kwargs)
        
        self.addRemoteVariables(       
            name        = 'LUT', 
            offset      = 0x10000, 
            number      =  2**ADDR_WIDTH_G, 
            bitSize     =  32, 
            bitOffset   =  0, 
            stride      =  4,
            mode        = "RW", 
            hidden      = True,
        )        
        
        self.add(TimingEmu(      
            name         = 'TimingEmu', 
            offset       = 0x20000, 
            expand       = False,
            ADDR_WIDTH_G = ADDR_WIDTH_G,
        ))         
