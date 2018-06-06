#!/bin/tcsh

exit

echo "Killing existing process"
killall rceServer

echo "Pausing for 1 second"
sleep 1

echo "Starting new process"
setenv SWDIR /mnt/host/atlas-rd53-daq/software
source $SWDIR/rceScripts/setup_rce.csh
cd $SWDIR; nohup python3 rceScripts/rceServer.py > /dev/null 
