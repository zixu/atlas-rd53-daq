# atlas-rd53-daq

# Before you clone the GIT repository

1) Create a github account:
> https://github.com/

2) On the Linux machine that you will clone the github from, generate a SSH key (if not already done)
> https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/

3) Add a new SSH key to your GitHub account
> https://help.github.com/articles/adding-a-new-ssh-key-to-your-github-account/

4) Setup for large filesystems on github

```
$ git lfs install
```

5) Verify that you have git version 2.13.0 (or later) installed 

```
$ git version
git version 2.13.0
```

6) Verify that you have git-lfs version 2.1.1 (or later) installed 

```
$ git-lfs version
git-lfs/2.1.1
```

# Clone the GIT repository

```
$ git clone --recursive git@github.com:slaclab/atlas-rd53-daq
```

# How to build the firmware

> Setup your Xilinx Vivado:

>> If you are on the SLAC AFS network:

```$ source atlas-rd53-daq/firmware/setup_env_slac.csh```

>> Else you will need to install Vivado and install the Xilinx Licensing

> Go to the firmware's target directory:

```$ cd atlas-rd53-daq/firmware/targets/AtlasRd53Pgp3_10Gbps```

> Build the firmware

```$ make```

> Optional: Open up the project in GUI mode to view the firmware build results

```$ make gui```

Note: For more information about the firmware build system, please refer to this presentation:

> https://docs.google.com/presentation/d/1kvzXiByE8WISo40Xd573DdR7dQU4BpDQGwEgNyeJjTI/edit?usp=sharing

# KCU1500 Firmware image with 8 lanes of PGPv3 at 10 Gbps/lane

> https://github.com/slaclab/pgp-pcie-apps/blob/master/firmware/targets/XilinxKcu1500Pgp3/images/XilinxKcu1500Pgp3-0x00000001-20180417135313-ruckman-21cf26d0_primary.mcs

> https://github.com/slaclab/pgp-pcie-apps/blob/master/firmware/targets/XilinxKcu1500Pgp3/images/XilinxKcu1500Pgp3-0x00000001-20180417135313-ruckman-21cf26d0_secondary.mcs

# How to program the KCU1500 with JTAG

> https://docs.google.com/presentation/d/10eIsAbLmslcNk94yV-F1D3hBfxudBf0EFo4xjcn9qPk/edit?usp=sharing

# How to load the driver

```
# Confirm that you have the board the computer with VID=1a4a ("SLAC") and PID=2030 ("DataDev")
$ lspci -nn | grep SLAC
04:00.0 Signal processing controller [1180]: SLAC National Accelerator Lab PPA-REG Device [1a4a:2030]

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

