# atlas-rd53-daq

<!--- ########################################################################################### -->

# Before you clone the GIT repository

1) Setup for large filesystems on github

```
$ git lfs install
```

2) Verify that you have git version 2.9.0 (or later) installed 

```
$ git version
git version 2.9.0
```

3) Verify that you have git-lfs version 2.1.1 (or later) installed 

```
$ git-lfs version
git-lfs/2.1.1
```

<!--- ########################################################################################### -->

# Clone the GIT repository

```
$ git clone --recursive https://github.com/slaclab/atlas-rd53-daq
```

<!--- ########################################################################################### -->

# How to build the Front End Board (FEB) firmware 

1) Setup your Xilinx Vivado:

> If you are on the SLAC AFS network:

```
$ source atlas-rd53-daq/firmware/setup_env_slac.csh
```

> Else you will need to install Vivado and install the Xilinx Licensing

2) Go to the firmware's target directory:

```
$ cd atlas-rd53-daq/firmware/targets/AtlasRd53Feb
```

3) Build the firmware

```
$ make
```

4) Optional: Open up the project in GUI mode to view the firmware build results

```
$ make gui
```

Note: For more information about the firmware build system, please refer to this presentation:

> https://docs.google.com/presentation/d/1kvzXiByE8WISo40Xd573DdR7dQU4BpDQGwEgNyeJjTI/edit?usp=sharing

<!--- ########################################################################################### -->

# How to build the KCU1500 PCIe card firmware 

1) Setup your Xilinx Vivado:

> If you are on the SLAC AFS network:

```
$ source atlas-rd53-daq/firmware/setup_env_slac.sh
```

> Else you will need to install Vivado and install the Xilinx Licensing

2) Go to the firmware's target directory:

```
$ cd atlas-rd53-daq/firmware/targets/AtlasRd53Kcu1500 
```

3) Build the firmware

```
$ make
```

4) Optional: Open up the project in GUI mode to view the firmware build results

```
$ make gui
```

Note: For more information about the Xilinx Kintex UltraScale FPGA KCU1500 Acceleration Development Kit:

> https://www.xilinx.com/products/boards-and-kits/dk-u1-kcu1500-g.html#hardware

# How to program the FEB with JTAG

> https://docs.google.com/presentation/d/11ldbniL1gEGyFjEdtmfclyITp-wX3TFjtWGtU0N2wZo/edit?usp=sharing

<!--- ########################################################################################### -->

# How to program the KCU1500 with JTAG

This is required if the SLAC firmware has not been programmed into the KCU1500 PROM yet (like factory defaults)

> https://docs.google.com/presentation/d/10eIsAbLmslcNk94yV-F1D3hBfxudBf0EFo4xjcn9qPk/edit?usp=sharing

<!--- ########################################################################################### -->

# How to load the driver

```
# Confirm that you have the board the computer with VID=1a4a ("SLAC") and PID=2030 ("DataDev")
$ lspci -nn | grep SLAC
04:00.0 Signal processing controller [1180]: SLAC National Accelerator Lab PPA-REG Device [1a4a:2030]

# If you don't see the "DataDev" device when doing this lspci, you will need to reprogram the PCIe card
# via JTAG.  After the JTAG reprogramming, you will need to do a full power cycle of PC (not reboot)

> https://docs.google.com/presentation/d/10eIsAbLmslcNk94yV-F1D3hBfxudBf0EFo4xjcn9qPk/edit?usp=sharing

# Clone the driver github repo:
$ git clone --recursive https://github.com/slaclab/aes-stream-drivers

# Go to the driver directory
$ cd aes-stream-drivers/data_dev/driver/

# Build the driver
$ make

# add new driver
$ sudo /sbin/insmod ./datadev.ko cfgSize=327680 cfgRxCount=128 cfgTxCount=128 || exit 1

# give appropriate group/permissions
$ sudo chmod 666 /dev/datadev_*

# Check for the loaded device
$ cat /proc/datadev_0

```

<!--- ########################################################################################### -->

# How to reprogram the FEB via PGPv3 link

```
# Go to software directory
$ cd atlas-rd53-daq/software

# If you are on the SLAC AFS network, 
$ source setup_env_slac.sh

# Else you will need to clone and build rogue:
> https://github.com/slaclab/rogue/blob/master/README.md

# Run the programming script
$ python3 scripts/PcieProgFeb.py --mcs <PATH_TO_FEB_MCS>
 
```

<!--- ########################################################################################### -->

# How to run the FEB Development GUI

```
# Go to software directory
$ cd atlas-rd53-daq/software

# If you are on the SLAC AFS network, 
$ source setup_env_slac.sh

# Else you will need to clone and build rogue:
> https://github.com/slaclab/rogue/blob/master/README.md

# Run the programming script
$ python3 scripts/PcieGui.py --guiType feb
 
```

<!--- ########################################################################################### -->
