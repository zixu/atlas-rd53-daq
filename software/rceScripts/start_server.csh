#!/bin/tcsh

exit

echo "Killing existing process"
killall python3

echo "Pausing for 1 second"
sleep 1

# Give appropriate group/permissions for DMA driver
chmod a+rw /dev/axi*

echo "Starting new process"
setenv SWDIR /mnt/host/atlas-rd53-daq/software/rceScripts
source $SWDIR/setup_rce.csh
cd $SWDIR; nohup python3 rceServer.py > /dev/null 
