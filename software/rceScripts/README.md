# Instructions for setuping up the RCE and running the GUI via python-pyro

If we are going to do these steps below for more than a few setups, then we will want to script the procedure below

```
################################################################################
# Note: In these instructions, we assume the single RCE node is IP=192.168.1.150
#       and that the PC that the NFS mounts to is IP=192.168.1.1
################################################################################

# Create a directory for NFS mounting
$ mkdir -p /u1/atlas
$ mkdir -p /u1/atlas/rd53a

# Setup /u1/atlas/rd53a for NFS mounting
$ nano /etc/exports; # Add "/u1/atlas/rd53a    192.168.0.0/16(rw,no_root_squash,async)"
$ service rpcbind restart ; service ypbind restart ; service nfs restart

# Check out the git repos
$ git clone --recursive https://github.com/slaclab/atlas-rd53-daq
$ git clone --recursive https://github.com/slaclab/aes-stream-drivers
$ git clone --recursive https://github.com/slaclab/rogue

# Build the aes-stream-driver
$ source /afs/slac/g/reseng/xilinx/vivado_2016.4/Vivado/2016.4/settings64.csh; # Vivado includes cross-compile libraries
$ cd /u1/atlas/rd53a/aes-stream-drivers
$ make rce

# Download the entire armv7h-mirror (Assumes you don't have internet access on RCE)
$ mkdir -p /u1/atlas/rd53a/mirror
$ cd /u1/atlas/rd53a/mirror
$ wget -m -np -nH http://ca.us.mirror.archlinuxarm.org/armv7h/

# Update the /bin/axistream.sh script
$ scp /u1/atlas/rd53a/atlas-rd53-daq/software/rceScripts/axistreamdma.sh.slac  root@192.168.1.150:/bin/axistreamdma.sh

# Log into the RCE and start the NFS mount (example is RCE at IP=192.168.1.150)
$ ssh root@192.168.1.150
$ /bin/axistreamdma.sh

# Update the pacman repo path (Assumes you don't have internet access on RCE)
$ nano /etc/pacman.d/mirrorlist
>> Comment out "Server = http://mirror.archlinuxarm.org/$arch/$repo"
>> Add "Server = file:///mnt/host/mirror/$arch/$repo"

# Update the /etc/pacman.conf
$ nano /etc/pacman.conf
>> Change "SigLevel    = Required DatabaseOptional" to "SigLevel    = Never"
>> Change "LocalFileSigLevel = Optional" to "LocalFileSigLevel = Never"

# Update system
$ rm /etc/ssl/certs/ca-certificates.crt
$ pacman -Scc
$ pacman-key --init
$ pacman -Syu

# Install the necessary packages for building rogue (choose default options)
# Note: Latest instructions documented in rogue/README.md <https://github.com/slaclab/rogue/blob/master/README.md>
$ pacman -S cmake
$ pacman -S tcsh
$ pacman -S python3
$ pacman -S boost
$ pacman -S bzip2
$ pacman -S python-pip
$ pacman -S git
$ pacman -S zeromq
$ pacman -S python-pyqt5
$ pacman -S python-pyqt4
$ pacman -S python-yaml 
$ pacman -S python-pyro
$ pacman -S python-parse 
$ pacman -S python-click 
$ pacman -S python-pyzmq 
$ pacman -S python-numpy 

# Build the rogue software
$ cd /mnt/host/rogue/
$ tcsh
$ source setup_rogue.csh
$ mkdir -p build
$ cd build
$ cmake ../
$ make -j 2

# Configure the latest image into the fpga.bit
$ /mnt/host/atlas-rd53-daq/firmware/targets/<RCE_TARGET>/images/<LATEST_RELEASE>.bit /mnt/boot/fpga.bit
$ sync; sync; sync
$ reboot

# After the RCE reboot, the rceServer will lauch automatically.
# On the PC client, lauch the GUI client
$ /u1/atlas/rd53a/atlas-rd53-daq/software
$ source setup_env_slac.csh
$ python3 scripts/RceGuiClient.py --cltIp 192.168.1.1 --srvIp 192.168.1.150

```
