#!/bin/sh                                                                                                                                                                        

# Disable Ethernet 
#   Refer to ifconfig for your ethernet interface name
#
sudo ifconfig enp4s0 down

# Tune powertop 
#   Run powertop --calibrate first
#   https://wiki.archlinux.org/index.php/powertop
#
sudo powertop --auto-tune

# Disable CPU Core 4-11 (4/6 phys cores) on battery mode
#   This applies for an Intel i7-8750H (6 cores, 12 threads)
#
echo 0 | sudo tee /sys/devices/system/cpu/cpu11/online
echo 0 | sudo tee /sys/devices/system/cpu/cpu10/online
echo 0 | sudo tee /sys/devices/system/cpu/cpu9/online
echo 0 | sudo tee /sys/devices/system/cpu/cpu8/online
echo 0 | sudo tee /sys/devices/system/cpu/cpu7/online
echo 0 | sudo tee /sys/devices/system/cpu/cpu6/online
echo 0 | sudo tee /sys/devices/system/cpu/cpu5/online
echo 0 | sudo tee /sys/devices/system/cpu/cpu4/online
