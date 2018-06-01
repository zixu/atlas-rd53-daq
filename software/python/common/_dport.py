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

class Dport(pr.Device):
    def __init__(   self,       
        name        = "Dport",
        description = "Container for DPORT registers",
        pollInterval = 1,
        **kwargs):
        
        super().__init__(
            name        = name,
            description = description,
            **kwargs)

        ##################
        # Status Registers 
        ##################
        self.add(pr.RemoteVariable(
            name         = 'DataDropCnt',
            description  = 'Increments when data dropped due to back pressure',
            offset       = 0x000,
            bitSize      = 32,
            mode         = 'RO',
            base         = pr.UInt,
            pollInterval = pollInterval,
        )) 
        
        self.add(pr.RemoteVariable(
            name         = 'CmdDropCnt',
            description  = 'Increments when cmd dropped due to back pressure',
            offset       = 0x004,
            bitSize      = 32, 
            mode         = 'RO',
            base         = pr.UInt,
            pollInterval = pollInterval,
        )) 
        
        self.add(pr.RemoteVariable(
            name         = 'TimedOutCnt',
            description  = 'Increments when a batcher timed out event occurs',
            offset       = 0x008,
            bitSize      = 32, 
            mode         = 'RO',
            base         = pr.UInt,
            pollInterval = pollInterval,
        ))         
        
        self.addRemoteVariables(   
            name         = 'AutoRead',
            description  = 'RD53 auto-read register',
            offset       = 0x410,
            bitSize      = 32,
            base         = pr.UInt,
            mode         = 'RO',
            number       = 4,
            stride       = 4,
            pollInterval = pollInterval,
        )               
        
        ##################
        # Status Registers 
        ##################        
        
        self.add(pr.RemoteVariable(
            name         = 'RollOverEn', 
            description  = 'Rollover enable for status counters',
            offset       = 0xFF8,
            bitSize      = 6, 
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
