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

class RxPhy(pr.Device):
    def __init__(   self,       
        name        = "RxPhy",
        description = "Container for RD53A RxPhy",
        cmdStream   = None,
        **kwargs):
        
        super().__init__(
            name        = name, 
            description = description, 
            size        = (0x1 << 16), 
            **kwargs)

        ###################################
        ###     Synchronous Front End   ###
        ###################################
        
        self.add(pr.RemoteVariable(
            name         = 'IBIASP1_SYNC', 
            description  = 'Cascode main branch bias current',
            offset       = (5 << 2),
            bitSize      = 9, 
            mode         = 'WO',
            value        = 100,
        )) 

        self.add(pr.RemoteVariable(
            name         = 'IBIASP2_SYNC', 
            description  = 'Input device main bias current',
            offset       = (6 << 2),
            bitSize      = 9, 
            mode         = 'WO',
            value        = 150,
        )) 

        self.add(pr.RemoteVariable(
            name         = 'IBIAS_SF_SYNC', 
            description  = 'Follower bias current',
            offset       = (7 << 2),
            bitSize      = 9, 
            mode         = 'WO',
            value        = 100,
        ))    

        self.add(pr.RemoteVariable(
            name         = 'IBIAS_KRUM_SYNC', 
            description  = 'Krummenacher feedback bias current',
            offset       = (8 << 2),
            bitSize      = 9, 
            mode         = 'WO',
            value        = 140,
        ))  

        self.add(pr.RemoteVariable(
            name         = 'IBIAS_DISC_SYNC', 
            description  = 'Comparator bias current',
            offset       = (9 << 2),
            bitSize      = 9, 
            mode         = 'WO',
            value        = 200,
            base         = pr.UInt,
        ))

        self.add(pr.RemoteVariable(
            name         = 'ICTRL_SYNCT_SYNC', 
            description  = 'Oscillator bias current',
            offset       = (10 << 2),
            bitSize      = 10, 
            mode         = 'WO',
            value        = 100,
            base         = pr.UInt,
        ))

        self.add(pr.RemoteVariable(
            name         = 'VBL_SYNC', 
            description  = 'Baseline voltage for offset compensation',
            offset       = (11 << 2),
            bitSize      = 10, 
            mode         = 'WO',
            value        = 450,
        )) 

        self.add(pr.RemoteVariable(
            name         = 'VTH_SYNC', 
            description  = 'Discriminator threshold voltage',
            offset       = (12 << 2),
            bitSize      = 10, 
            mode         = 'WO',
            value        = 300,
        )) 
        
        self.add(pr.RemoteVariable(
            name         = 'VREF_KRUM_SYNC', 
            description  = 'Krummenacher voltage reference',
            offset       = (13 << 2),
            bitSize      = 10, 
            mode         = 'WO',
            value        = 490,
        ))         
        
        self.add(pr.RemoteVariable(
            name         = 'AutoZero', 
            description  = 'Auto-zero[1:0]',
            offset       = (30 << 2),
            bitSize      = 2, 
            bitOffset    = 3,
            mode         = 'WO',
            value        = 0,
        ))  

        self.add(pr.RemoteVariable(
            name         = 'SelC2F', 
            description  = 'SelC2F',
            offset       = (30 << 2),
            bitSize      = 1, 
            bitOffset    = 2,
            mode         = 'WO',
            value        = 1,
        )) 

        self.add(pr.RemoteVariable(
            name         = 'SelC4F', 
            description  = 'SelC4F',
            offset       = (30 << 2),
            bitSize      = 1, 
            bitOffset    = 1,
            mode         = 'WO',
            value        = 0,
        ))

        self.add(pr.RemoteVariable(
            name         = 'FastToT', 
            description  = 'Fast ToT',
            offset       = (30 << 2),
            bitSize      = 1, 
            bitOffset    = 0,
            mode         = 'WO',
            value        = 0,
        ))              
       
        ###############################
        ###     Linear Front End    ###
        ###############################
        
        self.add(pr.RemoteVariable(
            name         = 'PA_IN_BIAS_LIN', 
            description  = 'Preamp input branch bias current',
            offset       = (14 << 2),
            bitSize      = 9, 
            mode         = 'WO',
            value        = 300,
        )) 

        self.add(pr.RemoteVariable(
            name         = 'FC_BIAS_LIN', 
            description  = 'Folded cascode branch current',
            offset       = (15 << 2),
            bitSize      = 8, 
            mode         = 'WO',
            value        = 20,
        )) 

        self.add(pr.RemoteVariable(
            name         = 'KRUM_CURR_LIN', 
            description  = 'Krummenacher feedback bias current',
            offset       = (16 << 2),
            bitSize      = 9, 
            mode         = 'WO',
            value        = 50,
            base         = pr.UInt,
        ))

        self.add(pr.RemoteVariable(
            name         = 'LDAC_LIN', 
            description  = 'Fine threshold voltage',
            offset       = (17 << 2),
            bitSize      = 10, 
            mode         = 'WO',
            value        = 80,
        )) 

        self.add(pr.RemoteVariable(
            name         = 'COMP_LIN', 
            description  = 'Comparator bias current',
            offset       = (18 << 2),
            bitSize      = 9, 
            mode         = 'WO',
            value        = 110,
            base         = pr.UInt,
        ))

        self.add(pr.RemoteVariable(
            name         = 'REF_KRUM_LIN', 
            description  = 'Krummenacher voltage reference',
            offset       = (19 << 2),
            bitSize      = 10, 
            mode         = 'WO',
            value        = 300,
        )) 

        self.add(pr.RemoteVariable(
            name         = 'Vthreshold_LIN', 
            description  = 'Global threshold voltage',
            offset       = (20 << 2),
            bitSize      = 10, 
            mode         = 'WO',
            value        = 408,
        ))         
        
        #####################################        
        ###     Differential Front End    ###
        #####################################        
        
        self.add(pr.RemoteVariable(
            name         = 'PRMP_DIFF', 
            description  = 'Preamp input stage bias current',
            offset       = (21 << 2),
            bitSize      = 10, 
            mode         = 'WO',
            value        = 533,
        )) 

        self.add(pr.RemoteVariable(
            name         = 'FOL_DIFF', 
            description  = 'Preamp follower bias current',
            offset       = (22 << 2),
            bitSize      = 10, 
            mode         = 'WO',
            value        = 542,
        ))  

        self.add(pr.RemoteVariable(
            name         = 'PRECOMP_DIFF', 
            description  = 'Precomparator tail current',
            offset       = (23 << 2),
            bitSize      = 10, 
            mode         = 'WO',
            value        = 551,
        ))  

        self.add(pr.RemoteVariable(
            name         = 'COMP_DIFF', 
            description  = 'Comparator bias current',
            offset       = (24 << 2),
            bitSize      = 10, 
            mode         = 'WO',
            value        = 528,
        )) 

        self.add(pr.RemoteVariable(
            name         = 'VFF_DIFF', 
            description  = 'Preamp feedback (discharge) current',
            offset       = (25 << 2),
            bitSize      = 10, 
            mode         = 'WO',
            value        = 164,
        ))    

        self.add(pr.RemoteVariable(
            name         = 'VTH1_DIFF', 
            description  = 'Negative branch threshold offset V (vth1)',
            offset       = (26 << 2),
            bitSize      = 10, 
            mode         = 'WO',
            value        = 1023,
        ))  

        self.add(pr.RemoteVariable(
            name         = 'VTH2_DIFF', 
            description  = 'Positive branch threshold offset V (vth2)',
            offset       = (27 << 2),
            bitSize      = 10, 
            mode         = 'WO',
            value        = 0,
        )) 

        self.add(pr.RemoteVariable(
            name         = 'LCC_DIFF', 
            description  = 'Leakage current compensation (LCC) bias',
            offset       = (28 << 2),
            bitSize      = 10, 
            mode         = 'WO',
            value        = 20,
        )) 

        self.add(pr.RemoteVariable(
            name         = 'LccEn', 
            description  = 'LccEn',
            offset       = (29 << 2),
            bitSize      = 1, 
            bitOffset    = 1,
            mode         = 'WO',
            value        = 1,
        ))

        self.add(pr.RemoteVariable(
            name         = 'AddFeedbackCap', 
            description  = 'AddFeedbackCap',
            offset       = (29 << 2),
            bitSize      = 1, 
            bitOffset    = 0,
            mode         = 'WO',
            value        = 0,
        ))            
        
        #################################
        ###     Power Supply Rails    ###
        #################################
        
        self.add(pr.RemoteVariable(
            name         = 'SLDO_ANALOG_TRIM', 
            description  = 'Analog regulator output voltage trim',
            offset       = (31 << 2),
            bitSize      = 5, 
            bitOffset    = 5,
            mode         = 'WO',
            value        = 16,
        ))        

        self.add(pr.RemoteVariable(
            name         = 'SLDO_DIGITAL_TRIM', 
            description  = 'Digital regulator output voltage trim',
            offset       = (31 << 2),
            bitSize      = 5, 
            bitOffset    = 0,
            mode         = 'WO',
            value        = 16,
        ))                
        
        #############################
        ###     Digital Matrix    ###
        #############################
        
        self.add(pr.RemoteVariable(
            name         = 'EN_CORE_COL_SYNC', 
            description  = 'Enable columns of cores w/ Sync. FE',
            offset       = (32 << 2),
            bitSize      = 16, 
            mode         = 'WO',
            value        = 0xFFFF,
        )) 

        self.add(pr.RemoteVariable(
            name         = 'EN_CORE_COL_LIN_1', 
            description  = 'Enable columns of cores w/ Linear FE',
            offset       = (33 << 2),
            bitSize      = 16, 
            mode         = 'WO',
            value        = 0xFFFF,
            base         = pr.UInt,
        ))

        self.add(pr.RemoteVariable(
            name         = 'EN_CORE_COL_LIN_2', 
            description  = 'Enable last column of cores w/ Linear FE',
            offset       = (34 << 2),
            bitSize      = 1, 
            mode         = 'WO',
            value        = 1,
            base         = pr.UInt,
        ))

        self.add(pr.RemoteVariable(
            name         = 'EN_CORE_COL_DIFF_1', 
            description  = 'Enable columns of cores w/ Diff. FE',
            offset       = (35 << 2),
            bitSize      = 16, 
            mode         = 'WO',
            value        = 0xFF,
            base         = pr.UInt,
        ))

        self.add(pr.RemoteVariable(
            name         = 'EN_CORE_COL_DIFF_2', 
            description  = 'Enable last column of cores w/ Diff. FE',
            offset       = (36 << 2),
            bitSize      = 1, 
            mode         = 'WO',
            value        = 1,
        ))  

        self.add(pr.RemoteVariable(
            name         = 'LATENCY_CONFIG', 
            description  = 'Trigger latency value',
            offset       = (37 << 2),
            bitSize      = 9, 
            mode         = 'WO',
            value        = 500,
        ))  

        self.add(pr.RemoteVariable(
            name         = 'WR_SYNC_DELAY_SYNC', 
            description  = 'Write synchronization delay for sync. FE',
            offset       = (38 << 2),
            bitSize      = 5, 
            mode         = 'WO',
            value        = 16,
        ))          
        
        ###############################
        ###         Injection       ###
        ###############################        
        
        self.add(pr.RemoteVariable(
            name         = 'InjAnaMode', 
            description  = 'InjAnaMode',
            offset       = (39 << 2),
            bitSize      = 1, 
            bitOffset    = 5,
            mode         = 'WO',
            value        = 0,
        )) 

        self.add(pr.RemoteVariable(
            name         = 'InjEnDig', 
            description  = 'InjEnDig',
            offset       = (39 << 2),
            bitSize      = 1, 
            bitOffset    = 4,
            mode         = 'WO',
            value        = 1,
        ))   

        self.add(pr.RemoteVariable(
            name         = 'InjDelay', 
            description  = 'InjDelay',
            offset       = (39 << 2),
            bitSize      = 4, 
            bitOffset    = 0,
            mode         = 'WO',
            value        = 0,
        ))           
        
        self.add(pr.RemoteVariable(
            name         = 'VCAL_HIGH', 
            description  = 'High injection voltage',
            offset       = (41 << 2),
            bitSize      = 12, 
            mode         = 'WO',
            value        = 500,
        )) 

        self.add(pr.RemoteVariable(
            name         = 'VCAL_MED', 
            description  = 'Medium injection voltage',
            offset       = (42 << 2),
            bitSize      = 12, 
            mode         = 'WO',
            value        = 300,
        ))         
        
        self.addRemoteVariables(   
            name         = 'CAL_COLPR_SYNC',
            description  = 'Enable CAL for 64 Sync. col. pairs',
            offset       = (46 << 2),
            bitSize      = 16,
            base         = pr.UInt,
            mode         = 'WO',
            value        = 0xFFFF,
            number       = 4,
            stride       = 4,
        )  

        self.addRemoteVariables(   
            name         = 'CAL_COLPR_LIN',
            description  = 'Enable CAL for 64 Linear col. pairs',
            offset       = (50 << 2),
            bitSize      = 16,
            base         = pr.UInt,
            mode         = 'WO',
            value        = 0xFFFF,
            number       = 4,
            stride       = 4,
        )          
        
        self.add(pr.RemoteVariable(
            name         = 'CAL_COLPR_LIN5', 
            description  = 'Enable CAL for last 4 Linear col. pairs',
            offset       = (54 << 2),
            bitSize      = 4, 
            mode         = 'WO',
            value        = 0xF,
        ))            
        
        self.addRemoteVariables(   
            name         = 'CAL_COLPR_DIFF',
            description  = 'Enable CAL for 64 Diff. col. pairs',
            offset       = (55 << 2),
            bitSize      = 16,
            base         = pr.UInt,
            mode         = 'WO',
            value        = 0xFFFF,
            number       = 4,
            stride       = 4,
        )          
        
        self.add(pr.RemoteVariable(
            name         = 'CAL_COLPR_DIFF5', 
            description  = 'Enable CAL for last 4 Diff. col. pairs',
            offset       = (59 << 2),
            bitSize      = 4, 
            mode         = 'WO',
            value        = 0xF,
        )) 

        self.add(pr.RemoteVariable(
            name         = 'CLK_DATA_DELAY', 
            description  = '2INV delay sel, delays for clock[3:0], command[3:0]',
            offset       = (40 << 2),
            bitSize      = 9, 
            mode         = 'WO',
            value        = 0,
        ))  

        self.add(pr.RemoteVariable(
            name         = 'CH_SYNC_CONF', 
            description  = 'Chan. synchronizer phase[1:0], lock[4:0], unlock thresh[4:0]',
            offset       = (43 << 2),
            bitSize      = 12, 
            mode         = 'WO',
            value        = 0x208,
        )) 

        self.add(pr.RemoteVariable(
            name         = 'GLOBAL_PULSE_RT', 
            description  = 'Selects routing of global pulse signal',
            offset       = (44 << 2),
            bitSize      = 16, 
            mode         = 'WO',
            value        = 0,
        ))         
        
        #########################
        ###         I/O       ###
        #########################
        
        self.add(pr.RemoteVariable(
            name         = 'DEBUG_CONFIG', 
            description  = 'EnableExtCal, EnablePRBS',
            offset       = (60 << 2),
            bitSize      = 2, 
            mode         = 'WO',
            value        = 0,
        )) 

        self.add(pr.RemoteVariable(
            name         = 'DataReadDelay', 
            description  = 'Number of 40MHz clocks +2 for data transfer out of pixel matrix. Default 0 means 2 clocks. May need higher value in case of large propagation delays, for example at low VDDD voltage after irradiation.',
            offset       = (61 << 2),
            bitSize      = 2, 
            bitOffset    = 7,
            mode         = 'WO',
            value        = 0,
        ))  

        self.add(pr.RemoteVariable(
            name         = 'OutputSerType', 
            description  = 'Default 0 for RD53A serializer (9.1). None other implemented so value 1 is meaningless.',
            offset       = (61 << 2),
            bitSize      = 1, 
            bitOffset    = 6,
            mode         = 'WO',
            value        = 0,
        ))         
        
        self.add(pr.RemoteVariable(
            name         = 'ActiveLanes', 
            description  = 'Aurora lanes. Default 0001 means single lane mode on lane 0.',
            offset       = (61 << 2),
            bitSize      = 4, 
            bitOffset    = 2,
            mode         = 'WO',
            value        = 1,
        )) 

        self.add(pr.RemoteVariable(
            name         = 'OutputFormat', 
            description  = 'Default 0 is header mode. 1 is tag mode. 2 is both header and tag. No other modes implemented (9.1)',
            offset       = (61 << 2),
            bitSize      = 2, 
            bitOffset    = 0,
            mode         = 'WO',
            value        = 0,
        ))    

        self.add(pr.RemoteVariable(
            name         = 'JTAG_TDO', 
            description  = 'default 0 = off',
            offset       = (62 << 2),
            bitSize      = 1, 
            bitOffset    = 0xD,
            mode         = 'WO',
            value        = 0,
        ))  

        self.add(pr.RemoteVariable(
            name         = 'STATUS_EN', 
            description  = 'default 1 = on',
            offset       = (62 << 2),
            bitSize      = 1, 
            bitOffset    = 0xC,
            mode         = 'WO',
            value        = 1,
        )) 

        self.add(pr.RemoteVariable(
            name         = 'STATUS_DS', 
            description  = 'default 0',
            offset       = (62 << 2),
            bitSize      = 1, 
            bitOffset    = 0xB,
            mode         = 'WO',
            value        = 0,
        )) 

        self.add(pr.RemoteVariable(
            name         = 'LANE0_LVDS', 
            description  = 'default 1 = off',
            offset       = (62 << 2),
            bitSize      = 1, 
            bitOffset    = 0xA,
            mode         = 'WO',
            value        = 1,
        ))  

        self.add(pr.RemoteVariable(
            name         = 'LANE0_LVDS_BIAS', 
            description  = 'default 0',
            offset       = (62 << 2),
            bitSize      = 3, 
            bitOffset    = 0x7,
            mode         = 'WO',
            value        = 0,
        ))  

        self.add(pr.RemoteVariable(
            name         = 'GP_LVDS_EN', 
            description  = 'default 0000 = all on',
            offset       = (62 << 2),
            bitSize      = 4, 
            bitOffset    = 0x3,
            mode         = 'WO',
            value        = 0,
        )) 

        self.add(pr.RemoteVariable(
            name         = 'GP_LVDS_BIAS', 
            description  = 'default 4',
            offset       = (62 << 2),
            bitSize      = 3, 
            bitOffset    = 0x0,
            mode         = 'WO',
            value        = 4,
        ))         
        
        self.add(pr.RemoteVariable(
            name         = 'GP_LVDS_ROUTE', 
            description  = 'Select signals connected to LVDS outputs',
            offset       = (63 << 2),
            bitSize      = 3, 
            mode         = 'WO',
            value        = 0,
        )) 

        self.add(pr.RemoteVariable(
            name         = 'CDR_SEL_DEL_CLK', 
            description  = 'Clock for delays (default 0 = 640MHz from PLL) Figs. 35, 36',
            offset       = (64 << 2),
            bitSize      = 1, 
            bitOffset    = 0xD,
            mode         = 'WO',
            value        = 0,
        )) 

        self.add(pr.RemoteVariable(
            name         = 'CDR_PD_SEL', 
            description  = '(default 0) see Fig. 35',
            offset       = (64 << 2),
            bitSize      = 2, 
            bitOffset    = 0xB,
            mode         = 'WO',
            value        = 0,
        ))   

        self.add(pr.RemoteVariable(
            name         = 'CDR_PD_DEL', 
            description  = '(default 8) see Fig. 35',
            offset       = (64 << 2),
            bitSize      = 4, 
            bitOffset    = 0x7,
            mode         = 'WO',
            value        = 8,
        ))  

        self.add(pr.RemoteVariable(
            name         = 'CDR_EN_GCK2', 
            description  = '(default 0) see Fig. 35',
            offset       = (64 << 2),
            bitSize      = 1, 
            bitOffset    = 0x6,
            mode         = 'WO',
            value        = 0,
        ))       

        self.add(pr.RemoteVariable(
            name         = 'CDR_VCO_GAIN', 
            description  = '(default 3) see Fig. 35',
            offset       = (64 << 2),
            bitSize      = 3, 
            bitOffset    = 0x3,
            mode         = 'WO',
            value        = 3,
        ))    

        self.add(pr.RemoteVariable(
            name         = 'CDR_SEL_SER_CLK', 
            description  = '(default 0 = 1.28 GHz from PLL) see Fig. 35',
            offset       = (64 << 2),
            bitSize      = 3, 
            bitOffset    = 0x0,
            mode         = 'WO',
            value        = 0,
        ))            
        
        self.add(pr.RemoteVariable(
            name         = 'VCO_BUFF_BIAS', 
            description  = 'Bias current for VCO buffer of CDR',
            offset       = (65 << 2),
            bitSize      = 10, 
            mode         = 'WO',
            value        = 400,
            base         = pr.UInt,
        ))
        
        self.add(pr.RemoteVariable(
            name         = 'CDR_CP_IBIAS', 
            description  = 'Bias current for CP of CDR',
            offset       = (66 << 2),
            bitSize      = 10, 
            mode         = 'WO',
            value        = 50,
        )) 

        self.add(pr.RemoteVariable(
            name         = 'VCO_IBIAS', 
            description  = 'Bias current for VCO',
            offset       = (67 << 2),
            bitSize      = 10, 
            mode         = 'WO',
            value        = 500,
        ))         
        
        for i in range(4):
            self.add(pr.RemoteVariable(
                name         = ('SER_SEL_OUT[%d]'%i), 
                description  = 'Sel. serializer for output, refer to section 9.1',
                offset       = (68 << 2),
                bitSize      = 2, 
                bitOffset    = (2*i),
                mode         = 'WO',
                value        = 1,
                base         = pr.UInt,
            ))          
        
        self.add(pr.RemoteVariable(
            name         = 'CmlInvTap', 
            description  = 'SER_INV_TAP (2b)',
            offset       = (69 << 2),
            bitSize      = 2, 
            bitOffset    = 6,
            mode         = 'WO',
            value        = 0,
        )) 

        self.add(pr.RemoteVariable(
            name         = 'CmlEnTap', 
            description  = 'SER_EN_TAP (2b)',
            offset       = (69 << 2),
            bitSize      = 2, 
            bitOffset    = 4,
            mode         = 'WO',
            value        = 3,
        )) 

        self.add(pr.RemoteVariable(
            name         = 'CmlEn', 
            description  = 'enable CMLs (4b)',
            offset       = (69 << 2),
            bitSize      = 4, 
            bitOffset    = 0,
            mode         = 'WO',
            value        = 0xF,
        ))         

        self.add(pr.RemoteVariable(
            name         = 'CML_TAP_BIAS[0]', 
            description  = 'CML driver pre-emphasis for taps',
            offset       = (70 << 2),
            bitSize      = 10, 
            mode         = 'WO',
            value        = 500,
        )) 

        self.add(pr.RemoteVariable(
            name         = 'CML_TAP_BIAS[1]', 
            description  = 'CML driver pre-emphasis for taps',
            offset       = (71 << 2),
            bitSize      = 10, 
            mode         = 'WO',
            value        = 0,
        ))  

        self.add(pr.RemoteVariable(
            name         = 'CML_TAP_BIAS[2]', 
            description  = 'CML driver pre-emphasis for taps',
            offset       = (72 << 2),
            bitSize      = 10, 
            mode         = 'WO',
            value        = 0,
            base         = pr.UInt,
        ))

        self.add(pr.RemoteVariable(
            name         = 'AuroraCcWait', 
            description  = 'Aurora values for CCwait(6b)',
            offset       = (73 << 2),
            bitSize      = 6, 
            bitOffset    = 2,
            mode         = 'WO',
            value        = 25,
        )) 

        self.add(pr.RemoteVariable(
            name         = 'AuroraCcSend', 
            description  = 'CCsend(2b)',
            offset       = (73 << 2),
            bitSize      = 2, 
            bitOffset    = 0,
            mode         = 'WO',
            value        = 3,
        ))         
        
        self.add(pr.RemoteVariable(
            name         = 'AuroraCbWaitLow', 
            description  = 'Aurora values for CBwait bits 3:0',
            offset       = (74 << 2),
            bitSize      = 4, 
            bitOffset    = 4,
            mode         = 'WO',
            value        = 15,
        )) 

        self.add(pr.RemoteVariable(
            name         = 'AuroraCbSend', 
            description  = 'CBsend(4b)',
            offset       = (74 << 2),
            bitSize      = 4, 
            bitOffset    = 0,
            mode         = 'WO',
            value        = 0,
        ))          
        
        self.add(pr.RemoteVariable(
            name         = 'AuroraCbWaitHigh', 
            description  = 'Aurora values for CBwait bits 19:4',
            offset       = (75 << 2),
            bitSize      = 16, 
            mode         = 'WO',
            value        = 0xF,
            base         = pr.UInt,
        ))

        self.add(pr.RemoteVariable(
            name         = 'AURORA_INIT_WAIT', 
            description  = 'Time to wait for channel bonding',
            offset       = (76 << 2),
            bitSize      = 11, 
            mode         = 'WO',
            value        = 32,
            base         = pr.UInt,
        ))

        self.add(pr.RemoteVariable(
            name         = 'MON_FRAME_SKIP', 
            description  = 'Interval between register/service/mon. frames',
            offset       = (45 << 2),
            bitSize      = 8, 
            mode         = 'WO',
            value        = 50,
            base         = pr.UInt,
        ))
        
        self.add(pr.RemoteVariable(
            name         = 'AUTO_READ_A[0]', 
            description  = 'Addresses of lane 0 registers for auto-read',
            offset       = (101 << 2),
            bitSize      = 8, 
            mode         = 'WO',
            value        = 136,
            base         = pr.UInt,
        ))

        self.add(pr.RemoteVariable(
            name         = 'AUTO_READ_B[0]', 
            description  = 'Addresses of lane 0 registers for auto-read',
            offset       = (102 << 2),
            bitSize      = 8, 
            mode         = 'WO',
            value        = 130,
            base         = pr.UInt,
        ))

        self.add(pr.RemoteVariable(
            name         = 'AUTO_READ_A[1]', 
            description  = 'Addresses of lane 1 registers for auto-read',
            offset       = (103 << 2),
            bitSize      = 8, 
            mode         = 'WO',
            value        = 118,
            base         = pr.UInt,
        ))

        self.add(pr.RemoteVariable(
            name         = 'AUTO_READ_B[1]', 
            description  = 'Addresses of lane 1 registers for auto-read',
            offset       = (104 << 2),
            bitSize      = 8, 
            mode         = 'WO',
            value        = 119,
            base         = pr.UInt,
        ))
        
        self.add(pr.RemoteVariable(
            name         = 'AUTO_READ_A[2]', 
            description  = 'Addresses of lane 2 registers for auto-read',
            offset       = (105 << 2),
            bitSize      = 8, 
            mode         = 'WO',
            value        = 120,
            base         = pr.UInt,
        ))

        self.add(pr.RemoteVariable(
            name         = 'AUTO_READ_B[2]', 
            description  = 'Addresses of lane 2 registers for auto-read',
            offset       = (106 << 2),
            bitSize      = 8, 
            mode         = 'WO',
            value        = 121,
            base         = pr.UInt,
        ))

        self.add(pr.RemoteVariable(
            name         = 'AUTO_READ_A[3]', 
            description  = 'Addresses of lane 3 registers for auto-read',
            offset       = (107 << 2),
            bitSize      = 8, 
            mode         = 'WO',
            value        = 122,
            base         = pr.UInt,
        ))

        self.add(pr.RemoteVariable(
            name         = 'AUTO_READ_B[3]', 
            description  = 'Addresses of lane 3 registers for auto-read',
            offset       = (108 << 2),
            bitSize      = 8, 
            mode         = 'WO',
            value        = 123,
            base         = pr.UInt,
        ))
        
        ###################################################
        ###         Test and Monitoring Functions       ###
        ###################################################
        
        self.add(pr.RemoteVariable(
            name         = 'MonitorEnable', 
            description  = 'Monitor enable(1b)',
            offset       = (77 << 2),
            bitSize      = 1, 
            bitOffset    = 13,
            mode         = 'WO',
            value        = 0,
        ))          
        
        self.add(pr.RemoteVariable(
            name         = 'MonitorImonMux', 
            description  = 'I_Mon mux(6b)',
            offset       = (77 << 2),
            bitSize      = 6, 
            bitOffset    = 7,
            mode         = 'WO',
            value        = 63,
        )) 

        self.add(pr.RemoteVariable(
            name         = 'MonitorVmonMux', 
            description  = 'V_Mon mux(7b)',
            offset       = (77 << 2),
            bitSize      = 7, 
            bitOffset    = 0,
            mode         = 'WO',
            value        = 127,
        ))         

        self.addRemoteVariables(   
            name         = 'HITOR_MASK_SYNC',
            description  = 'Disable 4 Hit-ORs for the 16 Sync. FE cores',
            offset       = (78 << 2),
            bitSize      = 16,
            base         = pr.UInt,
            mode         = 'WO',
            value        = 0,
            number       = 4,
            stride       = 4,
        )  

        self.addRemoteVariables(   
            name         = 'HITOR_MASK_LIN1',
            description  = 'Disable 4 Hit-ORs for 16 Linear FE cores',
            offset       = (82 << 2),
            bitSize      = 16,
            base         = pr.UInt,
            mode         = 'WO',
            value        = 0,
            number       = 4,
            stride       = 8,
        ) 

        self.addRemoteVariables(   
            name         = 'HITOR_MASK_LIN2',
            description  = 'Disable 4 Hit-ORs for 17th Linear FE core',
            offset       = (83 << 2),
            bitSize      = 1,
            base         = pr.UInt,
            mode         = 'WO',
            value        = 0,
            number       = 4,
            stride       = 8,
        ) 

        self.addRemoteVariables(   
            name         = 'HITOR_MASK_DIFF1',
            description  = 'Disable 4 Hit-ORs for 16 Diff. FE cores',
            offset       = (90 << 2),
            bitSize      = 16,
            base         = pr.UInt,
            mode         = 'WO',
            value        = 0,
            number       = 4,
            stride       = 8,
        ) 

        self.addRemoteVariables(   
            name         = 'HITOR_MASK_DIFF2',
            description  = 'Disable 4 Hit-ORs for 17th Diff. FE core',
            offset       = (91 << 2),
            bitSize      = 1,
            base         = pr.UInt,
            mode         = 'WO',
            value        = 0,
            number       = 4,
            stride       = 8,
        )         
        
        
        self.add(pr.RemoteVariable(
            name         = 'AdcRefTrim', 
            description  = 'Bandgap ref. trim',
            offset       = (98 << 2),
            bitSize      = 4, 
            bitOffset    = 6,
            mode         = 'WO',
            value        = 0,
        ))  

        self.add(pr.RemoteVariable(
            name         = 'AdcTrim', 
            description  = 'ADC trim',
            offset       = (98 << 2),
            bitSize      = 6, 
            bitOffset    = 0,
            mode         = 'WO',
            value        = 0,
        ))          

        self.addRemoteVariables(   
            name         = 'SENSOR_CONFIG',
            description  = 'Temperature sensor configuration (2 registers)',
            offset       = (99 << 2),
            bitSize      = 12,
            base         = pr.UInt,
            mode         = 'WO',
            value        = 0,
            number       = 2,
            stride       = 4,
        )         
        
        self.add(pr.RemoteVariable(
            name         = 'RING_OSC_ENABLE', 
            description  = 'Enable bits for 8 ring oscillators',
            offset       = (109 << 2),
            bitSize      = 8, 
            mode         = 'WO',
            value        = 0,
            base         = pr.UInt,
        ))
        
        self.addRemoteVariables(   
            name         = 'RING_OSC',
            description  = 'Read-only (write resets) counters for ring osc.',
            offset       = (110 << 2),
            bitSize      = 12,
            base         = pr.UInt,
            mode         = 'WO',
            value        = 0,
            number       = 8,
            stride       = 4,
        )         
        
        self.add(pr.RemoteVariable(
            name         = 'BC_CTR', 
            description  = 'Bunch crossing counter. Rd only (write resets)',
            offset       = (118 << 2),
            bitSize      = 16, 
            mode         = 'WO',
            value        = 0,
            base         = pr.UInt,
        ))

        self.add(pr.RemoteVariable(
            name         = 'TRIG_CTR', 
            description  = 'Trigger counter. Rd only (write resets)',
            offset       = (119 << 2),
            bitSize      = 16, 
            mode         = 'WO',
            value        = 0,
            base         = pr.UInt,
        )) 

        self.add(pr.RemoteVariable(
            name         = 'LCK_LOSS_CTR', 
            description  = 'Loss of lock ctr. on input stream (write resets)',
            offset       = (120 << 2),
            bitSize      = 16, 
            mode         = 'WO',
            value        = 0,
            base         = pr.UInt,
        ))         

        self.add(pr.RemoteVariable(
            name         = 'BFLIP_WARN_CTR', 
            description  = 'CMD bit flip warning ctr. (write resets)',
            offset       = (121 << 2),
            bitSize      = 16, 
            mode         = 'WO',
            value        = 0,
            base         = pr.UInt,
        ))         

        self.add(pr.RemoteVariable(
            name         = 'BFLIP_ERR_CTR', 
            description  = 'CMD bit flip error ctr. (write resets)',
            offset       = (122 << 2),
            bitSize      = 16, 
            mode         = 'WO',
            value        = 0,
            base         = pr.UInt,
        ))  

        self.add(pr.RemoteVariable(
            name         = 'CMD_ERR_CTR', 
            description  = 'CMD other error ctr. (write resets)',
            offset       = (123 << 2),
            bitSize      = 16, 
            mode         = 'WO',
            value        = 0,
            base         = pr.UInt,
        ))          
        
        self.addRemoteVariables(   
            name         = 'FIFO_FULL_CTR',
            description  = '8-bit counters of FIFO full conditions',
            offset       = (124 << 2),
            bitSize      = 16,
            base         = pr.UInt,
            mode         = 'WO',
            value        = 0,
            number       = 4,
            stride       = 4,
        )          
        
        self.add(pr.RemoteVariable(
            name         = 'AI_PIX_COL', 
            description  = 'Rd. only value of auto-incremented pixel colpr',
            offset       = (128 << 2),
            bitSize      = 8, 
            mode         = 'WO',
            value        = 0,
            base         = pr.UInt,
        )) 

        self.add(pr.RemoteVariable(
            name         = 'AI_PIX_ROW', 
            description  = 'Rd. only value of auto-incremented pixel row',
            offset       = (128 << 2),
            bitSize      = 9, 
            mode         = 'WO',
            value        = 0,
            base         = pr.UInt,
        ))         
        
        self.addRemoteVariables(   
            name         = 'HitOr_Cnt',
            description  = '16-bit rd. only cntr.s of Hit ORs (wrt. resets)',
            offset       = (130 << 2),
            bitSize      = 16,
            base         = pr.UInt,
            mode         = 'WO',
            value        = 0,
            number       = 4,
            stride       = 4,
        )          
        
        self.add(pr.RemoteVariable(
            name         = 'SKP_TRIG_CNT', 
            description  = '16-bit rd. only skipped trig ctr. (wrt. resets)',
            offset       = (134 << 2),
            bitSize      = 16, 
            mode         = 'WO',
            value        = 0,
            base         = pr.UInt,
        ))            
        
        self.add(pr.RemoteVariable(
            name         = 'ERR_MASK', 
            description  = 'Disable selected error/warning messages',
            offset       = (135 << 2),
            bitSize      = 14, 
            mode         = 'WO',
            value        = 0,
            base         = pr.UInt,
        ))
        
        self.add(pr.RemoteVariable(
            name         = 'ADC_READ', 
            description  = 'read only ADC value. Must first run ADC',
            offset       = (136 << 2),
            bitSize      = 11, 
            mode         = 'WO',
            value        = 0,
            base         = pr.UInt,
        ))    

        self.add(pr.RemoteVariable(
            name         = 'SELF_TRIG_EN', 
            description  = 'Not implemented in RD53A. No function.',
            offset       = (137 << 2),
            bitSize      = 4, 
            mode         = 'WO',
            value        = 0,
            base         = pr.UInt,
        ))            
        
        ###########################################
        ###         Pixel Configurations        ###
        ###########################################
        self.add(pr.LocalVariable(    
            name         = 'pix_en',
            description  = "Pixel Power and Enable",
            mode         = "RW",
            value        = {col: {row: 0 for row in range(192)} for col in range(400)},
            minimum      = 0,
            maximum      = 1,
            hidden       = True,
        ))  

        self.add(pr.LocalVariable(    
            name         = 'pix_injen',
            description  = "Injection Enable",
            mode         = "RW",
            value        = {col: {row: 0 for row in range(192)} for col in range(400)},                  
            minimum      = 0,
            maximum      = 1,
            hidden       = True,
        ))

        self.add(pr.LocalVariable(    
            name         = 'pix_hitbus',
            description  = "Hit-OR-bus Enable",
            mode         = "RW",
            value        = {col: {row: 0 for row in range(192)} for col in range(400)},                  
            minimum      = 0,
            maximum      = 1,
            hidden       = True,
        )) 

        self.add(pr.LocalVariable(    
            name         = 'pix_tdac',
            description  = "TDAC",
            mode         = "RW",
            value        = {col: {row: 0 for row in range(192)} for col in range(400)},                  
            minimum      = 0,
            maximum      = 15,
            hidden       = True,
        ))         
        
        self.add(pr.LocalVariable(    
            name         = 'pix_sign',
            description  = "Diff=TDAC Sign, Linear=GainSelection, Sync=Unused",
            mode         = "RW",
            value        = {col: {row: 0 for row in range(192)} for col in range(400)},                  
            minimum      = 0,
            maximum      = 1,
            hidden       = True,
        ))        
                
        def getPixValue(col,row):
            # en     = self.node(f'pix_{col}_{row}_en').get()
            # injen  = self.node(f'pix_{col}_{row}_injen').get()
            # hitbus = self.node(f'pix_{col}_{row}_hitbus').get()
            # tdac   = self.node(f'pix_{col}_{row}_tdac').get()
            # sign   = self.node(f'pix_{col}_{row}_sign').get()
            # return (sign<<7) | (tdac<<3) | (hitbus<<2) | (injen<<1) | en
            return 0

        ##############################
        # Commands
        ##############################
        @self.command(name= "LoadPixConfig", description  = "Loads the Pixel Configuration")        
        def LoadPixConfig():         
            # Create a configuration list
            config = [None] * (192+3)
            # Unlock the pixel configurations
            self._rawWrite(offset=(4<<2), data=0x0)            
            # Loop through the matrix
            for col in range(400>>1):
                # print (col)
                ################################################
                # Address[3].BIT[5:5] = PixBroadcastEn
                # Address[3].BIT[4:4] = PixAutoCol
                # Address[3].BIT[3:3] = PixAutoRow
                # Address[3].BIT[2:0] = PixBroadcastMask
                ################################################
                config[0] = (3 << 16) | 0x8 # PixAutoCol enabled
                ################################################
                # Address[2].BIT[8:0] = PixRegionRow
                ################################################
                config[1] = (2 << 16) | 0 
                ################################################
                # Address[1].BIT[7:0] = PixRegionCol
                ################################################                
                config[2] = (1 << 16) | col
                # Fill the list with row configuration
                for row in range(192):
                    config[row+3] = (getPixValue((2*col)+1,row) << 8) | getPixValue((2*col),row)
                # Load the configuration into the ASIC
                self._rawWrite(
                    offset      = 0x8000,
                    data        = config,
                    posted      = True,
                )
            # Lock the pixel configurations
            self._rawWrite(offset=(4<<2), data=0x9CE2)                  