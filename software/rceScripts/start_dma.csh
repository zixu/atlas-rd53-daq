#!/bin/csh

set kernel=`uname -r`
@ length = ( `expr index $kernel "-"` - 1 )
set version=`expr substr $kernel 1 $length`
set driver_version=${version}.arm
set driver_dir=/mnt/host/aes-stream-drivers/install/${driver_version}

echo kernel         = $kernel
echo length         = $length
echo version        = $version
echo driver_version = $driver_version
echo driver_dir     = $driver_dir
 
# Remove old drivers
/sbin/rmmod -s rcestream
/sbin/rmmod -s rce_memmap 
 
# Load the drivers
insmod ${driver_dir}/rcestream.ko cfgTxCount0=8 cfgTxCount2=8 cfgRxCount0=32 cfgRxCount2=32 cfgSize0=131072 cfgSize2=131072 cfgMode2=20
insmod ${driver_dir}/rce_memmap.ko

# Give appropriate group/permissions for DMA driver
chmod a+rw /dev/axi*
