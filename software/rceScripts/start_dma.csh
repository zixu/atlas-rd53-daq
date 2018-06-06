#!/bin/csh

set kernel=`uname -r`
@ length = ( `expr index $kernel "-"` - 1 )
set version=`expr substr $kernel 1 $length`
set driver_version=${version}.arm
set driver_dir=/mnt/host/aes-stream-drivers/install/${driver_version}
set driver=${driver_dir}/rcestream.ko

echo kernel         = $kernel
echo length         = $length
echo version        = $version
echo driver_version = $driver_version
echo driver_dir     = $driver_dir
echo driver         = $driver
 
# Load the driver
insmod ${driver} cfgTxCount0=8 cfgTxCount1=8 cfgTxCount2=8 cfgRxCount0=32 cfgRxCount1=8 cfgRxCount2=32 cfgSize0=131072 cfgSize2=131072 cfgMode2=20

# give appropriate group/permissions
chmod a+rw /dev/axi*

