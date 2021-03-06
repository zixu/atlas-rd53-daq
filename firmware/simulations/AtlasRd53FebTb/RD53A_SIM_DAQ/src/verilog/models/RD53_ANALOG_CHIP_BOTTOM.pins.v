
/*   AUTOMATICALLY GENERATED BY oa2verilog - DO NOT EDIT   */

// Verilog file for cell "RD53_ANALOG_CHIP_BOTTOM" view "symbol" 
// Language Version: 2001 

module RD53_ANALOG_CHIP_BOTTOM (
    ADC_CLK40,
    ADC_EOC_B,
    ADC_OUT,
    ADC_RST_B,
    ADC_SOC,
    ADC_TRIM,
    BYPASS_CDR,
    CAL_HI_BG,
    CAL_HI_R_LBNL,
    CAL_HI_L_LBNL,
    CAL_HI_TO,
    CAL_MI_BG,
    CAL_MI_R_LBNL,
    CAL_MI_L_LBNL,
    CAL_MI_TO,
    CDR_CMD_CLK,
    CDR_CMD_DATA_IN,
    CDR_CMD_DATA_OUT,
    CDR_DEL_CLK,
    CDR_EN_GCK2,
    CDR_PD_DEL,
    CDR_PD_SEL,
    CDR_SEL_DEL_CLK,
    PLL_RST_B,
    CDR_SEL_SER_CLK,
    CDR_SER_CLK,
    CDR_VCO_GAIN,
    COMPVBN_LBNL,
    COMP_BIAS_BG,
    CURR_CML_BIAS_1,
    CURR_CML_BIAS_2,
    CURR_CML_BIAS_3,
    DAC_CAL_HI,
    DAC_CAL_MI,
    DAC_CML_BIAS_1,
    DAC_CML_BIAS_2,
    DAC_CML_BIAS_3,
    DAC_COMPVBN_LBNL,
    DAC_COMP_BG,
    DAC_CP_CDR,
    DAC_FC_BIAS_BG,
    DAC_GDAC_BG,
    DAC_IBIASP1_TO,
    DAC_IBIASP2_TO,
    DAC_IBIAS_DISC_TO,
    DAC_IBIAS_SF_TO,
    DAC_ICTRLTOT_TO,
    DAC_IFEED_TO,
    DAC_KRUM_CURR_BG,
    DAC_LDAC_BG,
    DAC_PA_IN_BIAS_BG,
    DAC_PRECOMPVBN_LBNL,
    DAC_PREVBNFOL_LBNL,
    DAC_PREVBP_LBNL,
    DAC_REF_KRUM_BG,
    DAC_REF_KRUM_TO,
    DAC_VBLCC_LBNL,
    DAC_VBL_TO,
    DAC_VCOBUFF_CDR,
    DAC_VCO_CDR,
    DAC_VFF_LBNL,
    DAC_VTH1_LBNL,
    DAC_VTH2_LBNL,
    DAC_VTH_TO,
    DET_GRD,
    EN_CAL_BG,
    EN_CAL_LBNL,
    EN_CAL_TO,
    EXT_CMD_CLK,
    EXT_SER_CLK,
    GNDA,
    GNDD,
    GND_PLL,
    GWT_320_CLK,
    IBIASP1_TO,
    IBIASP2_TO,
    IBIAS_DISC_TO,
    IBIAS_FEED_TO,
    IBIAS_SF_TO,
    ICTRL_TOT_TO,
    IFC_BIAS_BG,
    IHD_KRUM_BG,
    IHU_KRUM_BG,
    ILDAC_MIR1_BG,
    ILDAC_MIR2_BG,
    IMUX_OUT,
    IPA_IN_BIAS_BG,
    IREF_IN,
    IREF_OUT,
    IREF_TRIM,
    LOW_JITTER_EN,
    MON_4UA_REF,
    MON_BG_TRIM,
    MON_CML_BIAS_1,
    MON_CML_BIAS_2,
    MON_CML_BIAS_3,
    MON_COMPVBN_LBNL,
    MON_COMP_BG,
    MON_CP_CDR,
    MON_ENABLE,
    MON_FC_BIAS_BG,
    MON_IBIASP1_TO,
    MON_IBIASP2_TO,
    MON_IBIAS_DISC_TO,
    MON_IBIAS_SF_TO,
    MON_ICTRL_TOT_TO,
    MON_IFEED_TO,
    MON_KRUM_CURR_BG,
    MON_LDAC_BG,
    MON_PA_IN_BIAS_A_BG,
    MON_PRECOMPVBN_LBNL,
    MON_PREVBNFOL_LBNL,
    MON_PREVBP_LBNL,
    MON_SENS_DEM1,
    MON_SENS_DEM2,
    MON_SENS_DEM3,
    MON_SENS_DEM4,
    MON_SENS_ENABLE1,
    MON_SENS_ENABLE2,
    MON_SENS_ENABLE3,
    MON_SENS_ENABLE4,
    MON_SENS_SELBIAS1,
    MON_SENS_SELBIAS2,
    MON_SENS_SELBIAS3,
    MON_SENS_SELBIAS4,
    MON_VBLCC_LBNL,
    MON_VCOBUFF_CDR,
    MON_VCO_CDR,
    MON_VFF_LBNL,
    MON_VIN_SEL,
    MON_VTH1_LBNL,
    MON_VTH2_LBNL,
    POR_BGP,
    POR_EXT_CAP,
    POR_OUT_B,
    POR_DIG_B,
    PRECOMPVBN_LBNL,
    PRMPVBNFOL_LBNL,
    PRMPVBP_LBNL,
    RING_OSC_COUNT_CKND0,
    RING_OSC_COUNT_CKND4,
    RING_OSC_COUNT_INVD0,
    RING_OSC_COUNT_INVD4,
    RING_OSC_COUNT_NAND0,
    RING_OSC_COUNT_NAND4,
    RING_OSC_COUNT_NORD0,
    RING_OSC_COUNT_NORD4,
    RING_OSC_EN_CKND0,
    RING_OSC_EN_CKND4,
    RING_OSC_EN_INVD0,
    RING_OSC_EN_INVD4,
    RING_OSC_EN_NAND0,
    RING_OSC_EN_NAND4,
    RING_OSC_EN_NORD0,
    RING_OSC_EN_NORD4,
    RING_OSC_RESET,
    RING_OSC_START_STOPN,
    VBL_DISC_TO,
    VBNLCC_LBNL,
    VCASN_DISC_TO,
    VCASN_TO,
    VCASP1_TO,
    VCAS_KRUM_TO,
    VCTRCF0_R_LBNL, VCTRCF0_L_LBNL,
    VCTRLCC_R_LBNL, VCTRLCC_L_LBNL,
    VDDA,
    VDDD,
    VDD_PLL,
    VFF_LBNL,
    VINJ_HI,
    VINJ_MID,
    VMON_LDO_ANALOG_ISHUNT,
    VMON_LDO_ANALOG_ISUPPLY,
    VMON_LDO_ANALOG_VIN,
    VMON_LDO_ANALOG_VOFFSET,
    VMON_LDO_ANALOG_VOUT,
    VMON_LDO_ANALOG_VREF,
    VMON_LDO_DIGITAL_ISHUNT,
    VMON_LDO_DIGITAL_ISUPPLY,
    VMON_LDO_DIGITAL_VIN,
    VMON_LDO_DIGITAL_VOFFSET,
    VMON_LDO_DIGITAL_VOUT,
    VMON_LDO_DIGITAL_VREF,
    VMUX_OUT,
    VREF_ADC_IN,
    VREF_ADC_OUT,
    VREF_KRUM_TO,
    VRIF_KRUM_BG,
    VSUB,
    VTHIN1_LBNL,
    VTHIN2_LBNL,
    VTH_BG,
    VTH_DISC_TO,
    VCTRLCC_R_DIG_LBNL,
    VCTRLCC_L_DIG_LBNL,
    VCTRCF0_R_DIG_LBNL,
    VCTRCF0_L_DIG_LBNL,
    PLL_VCTRL
    );

    input wire ADC_CLK40;
    output wire ADC_EOC_B;
    output wire [11:0] ADC_OUT;
    input wire ADC_RST_B;
    input wire ADC_SOC;
    input wire [5:0] ADC_TRIM;
    input wire BYPASS_CDR;
    inout wire [67:0] CAL_HI_BG;
    inout wire [67:0] CAL_HI_R_LBNL;
    inout wire [67:0] CAL_HI_L_LBNL;
    inout wire [63:0] CAL_HI_TO;
    inout wire [67:0] CAL_MI_BG;
    inout wire [67:0] CAL_MI_R_LBNL;
    inout wire [67:0] CAL_MI_L_LBNL;
    inout wire [63:0] CAL_MI_TO;
    output wire CDR_CMD_CLK;
    input wire CDR_CMD_DATA_IN;
    output wire CDR_CMD_DATA_OUT;
    output wire CDR_DEL_CLK;
    input wire CDR_EN_GCK2;
    input wire [3:0] CDR_PD_DEL;
    input wire [1:0] CDR_PD_SEL;
    input wire CDR_SEL_DEL_CLK;
    input wire PLL_RST_B;
    input wire [2:0] CDR_SEL_SER_CLK;
    output wire CDR_SER_CLK;
    input wire [2:0] CDR_VCO_GAIN;
    inout wire [67:0] COMPVBN_LBNL;
    inout wire [67:0] COMP_BIAS_BG;
    inout wire CURR_CML_BIAS_1;
    inout wire CURR_CML_BIAS_2;
    inout wire CURR_CML_BIAS_3;
    input wire [11:0] DAC_CAL_HI;
    input wire [11:0] DAC_CAL_MI;
    input wire [9:0] DAC_CML_BIAS_1;
    input wire [9:0] DAC_CML_BIAS_2;
    input wire [9:0] DAC_CML_BIAS_3;
    input wire [9:0] DAC_COMPVBN_LBNL;
    input wire [9:0] DAC_COMP_BG;
    input wire [9:0] DAC_CP_CDR;
    input wire [9:0] DAC_FC_BIAS_BG;
    input wire [9:0] DAC_GDAC_BG;
    input wire [9:0] DAC_IBIASP1_TO;
    input wire [9:0] DAC_IBIASP2_TO;
    input wire [9:0] DAC_IBIAS_DISC_TO;
    input wire [9:0] DAC_IBIAS_SF_TO;
    input wire [9:0] DAC_ICTRLTOT_TO;
    input wire [9:0] DAC_IFEED_TO;
    input wire [9:0] DAC_KRUM_CURR_BG;
    input wire [9:0] DAC_LDAC_BG;
    input wire [9:0] DAC_PA_IN_BIAS_BG;
    input wire [9:0] DAC_PRECOMPVBN_LBNL;
    input wire [9:0] DAC_PREVBNFOL_LBNL;
    input wire [9:0] DAC_PREVBP_LBNL;
    input wire [9:0] DAC_REF_KRUM_BG;
    input wire [9:0] DAC_REF_KRUM_TO;
    input wire [9:0] DAC_VBLCC_LBNL;
    input wire [9:0] DAC_VBL_TO;
    input wire [9:0] DAC_VCOBUFF_CDR;
    input wire [9:0] DAC_VCO_CDR;
    input wire [9:0] DAC_VFF_LBNL;
    input wire [9:0] DAC_VTH1_LBNL;
    input wire [9:0] DAC_VTH2_LBNL;
    input wire [9:0] DAC_VTH_TO;
    inout wire [1:0] DET_GRD;
    input wire [67:0] EN_CAL_BG;
    input wire [67:0] EN_CAL_LBNL;
    input wire [63:0] EN_CAL_TO;
    input wire EXT_CMD_CLK;
    input wire EXT_SER_CLK;
    inout wire GNDA;
    inout wire GNDD;
    inout wire GND_PLL;
    output wire GWT_320_CLK;
    inout wire [63:0] IBIASP1_TO;
    inout wire [63:0] IBIASP2_TO;
    inout wire [63:0] IBIAS_DISC_TO;
    inout wire [63:0] IBIAS_FEED_TO;
    inout wire [63:0] IBIAS_SF_TO;
    inout wire [63:0] ICTRL_TOT_TO;
    inout wire [67:0] IFC_BIAS_BG;
    inout wire [67:0] IHD_KRUM_BG;
    inout wire [67:0] IHU_KRUM_BG;
    inout wire [67:0] ILDAC_MIR1_BG;
    inout wire [67:0] ILDAC_MIR2_BG;
    inout wire IMUX_OUT;
    inout wire [67:0] IPA_IN_BIAS_BG;
    inout wire IREF_IN;
    inout wire IREF_OUT;
    input wire [3:0] IREF_TRIM;
    input wire LOW_JITTER_EN;
    input wire MON_4UA_REF;
    input wire [4:0] MON_BG_TRIM;
    input wire MON_CML_BIAS_1;
    input wire MON_CML_BIAS_2;
    input wire MON_CML_BIAS_3;
    input wire MON_COMPVBN_LBNL;
    input wire MON_COMP_BG;
    input wire MON_CP_CDR;
    input wire MON_ENABLE;
    input wire MON_FC_BIAS_BG;
    input wire MON_IBIASP1_TO;
    input wire MON_IBIASP2_TO;
    input wire MON_IBIAS_DISC_TO;
    input wire MON_IBIAS_SF_TO;
    input wire MON_ICTRL_TOT_TO;
    input wire MON_IFEED_TO;
    input wire MON_KRUM_CURR_BG;
    input wire MON_LDAC_BG;
    input wire MON_PA_IN_BIAS_A_BG;
    input wire MON_PRECOMPVBN_LBNL;
    input wire MON_PREVBNFOL_LBNL;
    input wire MON_PREVBP_LBNL;
    input wire [3:0] MON_SENS_DEM1;
    input wire [3:0] MON_SENS_DEM2;
    input wire [3:0] MON_SENS_DEM3;
    input wire [3:0] MON_SENS_DEM4;
    input wire MON_SENS_ENABLE1;
    input wire MON_SENS_ENABLE2;
    input wire MON_SENS_ENABLE3;
    input wire MON_SENS_ENABLE4;
    input wire MON_SENS_SELBIAS1;
    input wire MON_SENS_SELBIAS2;
    input wire MON_SENS_SELBIAS3;
    input wire MON_SENS_SELBIAS4;
    input wire MON_VBLCC_LBNL;
    input wire MON_VCOBUFF_CDR;
    input wire MON_VCO_CDR;
    input wire MON_VFF_LBNL;
    input wire [39:0] MON_VIN_SEL;
    input wire MON_VTH1_LBNL;
    input wire MON_VTH2_LBNL;
    input wire POR_BGP;
    inout wire POR_EXT_CAP;
    inout wire POR_OUT_B;
    output wire POR_DIG_B;
    inout wire [67:0] PRECOMPVBN_LBNL;
    inout wire [67:0] PRMPVBNFOL_LBNL;
    inout wire [67:0] PRMPVBP_LBNL;
    output wire [15:0] RING_OSC_COUNT_CKND0;
    output wire [15:0] RING_OSC_COUNT_CKND4;
    output wire [15:0] RING_OSC_COUNT_INVD0;
    output wire [15:0] RING_OSC_COUNT_INVD4;
    output wire [15:0] RING_OSC_COUNT_NAND0;
    output wire [15:0] RING_OSC_COUNT_NAND4;
    output wire [15:0] RING_OSC_COUNT_NORD0;
    output wire [15:0] RING_OSC_COUNT_NORD4;
    input wire RING_OSC_EN_CKND0;
    input wire RING_OSC_EN_CKND4;
    input wire RING_OSC_EN_INVD0;
    input wire RING_OSC_EN_INVD4;
    input wire RING_OSC_EN_NAND0;
    input wire RING_OSC_EN_NAND4;
    input wire RING_OSC_EN_NORD0;
    input wire RING_OSC_EN_NORD4;
    input wire RING_OSC_RESET;
    input wire RING_OSC_START_STOPN;
    inout wire [63:0] VBL_DISC_TO;
    inout wire [67:0] VBNLCC_LBNL;
    inout wire [63:0] VCASN_DISC_TO;
    inout wire [63:0] VCASN_TO;
    inout wire [63:0] VCASP1_TO;
    inout wire [63:0] VCAS_KRUM_TO;
    inout wire [67:0] VCTRCF0_R_LBNL;
    inout wire [67:0] VCTRCF0_L_LBNL;
    inout wire [67:0] VCTRLCC_R_LBNL;
    inout wire [67:0] VCTRLCC_L_LBNL;
    inout wire VDDA;
    inout wire VDDD;
    inout wire VDD_PLL;
    inout wire [67:0] VFF_LBNL;
    inout wire VINJ_HI;
    inout wire VINJ_MID;
    input wire VMON_LDO_ANALOG_ISHUNT;
    input wire VMON_LDO_ANALOG_ISUPPLY;
    input wire VMON_LDO_ANALOG_VIN;
    input wire VMON_LDO_ANALOG_VOFFSET;
    input wire VMON_LDO_ANALOG_VOUT;
    input wire VMON_LDO_ANALOG_VREF;
    input wire VMON_LDO_DIGITAL_ISHUNT;
    input wire VMON_LDO_DIGITAL_ISUPPLY;
    input wire VMON_LDO_DIGITAL_VIN;
    input wire VMON_LDO_DIGITAL_VOFFSET;
    input wire VMON_LDO_DIGITAL_VOUT;
    input wire VMON_LDO_DIGITAL_VREF;
    inout wire VMUX_OUT;
    inout wire VREF_ADC_IN;
    inout wire VREF_ADC_OUT;
    inout wire [63:0] VREF_KRUM_TO;
    inout wire [67:0] VRIF_KRUM_BG;
    inout wire VSUB;
    inout wire [67:0] VTHIN1_LBNL;
    inout wire [67:0] VTHIN2_LBNL;
    inout wire [67:0] VTH_BG;
    inout wire [63:0] VTH_DISC_TO;
    input wire [67:0] VCTRLCC_R_DIG_LBNL; 
    input wire [67:0] VCTRLCC_L_DIG_LBNL;
    input wire [67:0] VCTRCF0_R_DIG_LBNL;
    input wire [67:0] VCTRCF0_L_DIG_LBNL;
    input wire PLL_VCTRL;

endmodule // RD53_ANALOG_CHIP_BOTTOM


