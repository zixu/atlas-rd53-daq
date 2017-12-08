# atlas-rd53-daq

# Before you clone the GIT repository

> Setup for large filesystems on github

```$ git lfs install```

> Verify that you have git version 2.13.0 (or later) installed 

```
$ git version
git version 2.13.0
```

> Verify that you have git-lfs version 2.1.1 (or later) installed 

```
$ git-lfs version
git-lfs/2.1.1
```

# Clone the GIT repository

```$ git clone --recursive https://github.com/slaclab/atlas-rd53-daq```

# How to build the firmware

> Setup your Xilinx Vivado:

>> If you are on the SLAC AFS network:

```$ source atlas-rd53-daq/firmware/setup_slac.csh```

>> Else you will need to install Vivado and install the Xilinx Licensing

> Go to the firmware's target directory:

```$ cd atlas-rd53-daq/firmware/targets/AtlasRd43Pgp3```

> Build the firmware

```$ make```

> Optional: Open up the project in GUI mode to view the firmware build results

```$ make gui```

# How to program the KCU1500
> https://docs.google.com/presentation/d/10eIsAbLmslcNk94yV-F1D3hBfxudBf0EFo4xjcn9qPk/edit?usp=sharing

# How to load the driver

```
# Clone the driver github repo (at KCU1500 devolopment branch):
$ git clone --recursive -b kcu1500-dev https://github.com/slaclab/aes-stream-drivers

# Go to the driver directory
$ cd aes-stream-drivers/data_dev/driver/

# Build the driver
$ make

# Execute load script as sudo
$ sudo <base-directory>/atlas-rd53-daq/software/driver_load

# Check for the loaded device
$ cat /proc/data_dev0

```
