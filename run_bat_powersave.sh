#!/bin/sh                                                                                                                                                                        

# Disable Ethernet 
#    Refer to ifconfig for your ethernet interface name. See below example:
#-------------------
# #tuanho@precision: ~/repo/batteryimprove (master)
# $ ifconfig
# enp0s31f6: flags=4099<UP,BROADCAST,MULTICAST>  mtu 1500
#         ether a0:29:19:21:7b:ca  txqueuelen 1000  (Ethernet)
#         RX packets 0  bytes 0 (0.0 B)
#         RX errors 0  dropped 0  overruns 0  frame 0
#         TX packets 0  bytes 0 (0.0 B)
#         TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
#         device interrupt 16  memory 0xb7380000-b73a0000  
#-------------------
#
sudo ifconfig enp0s31f6 down

# Tune powertop 
#   Run powertop --calibrate first
#   https://wiki.archlinux.org/index.php/powertop
#
sudo powertop --auto-tune

# Disable CPU Core 4-11 (4/6 phys cores) on battery mode
#   This applies for an Intel CPU with physical 6 cores
#
# echo 0 | sudo tee /sys/devices/system/cpu/cpu11/online
# echo 0 | sudo tee /sys/devices/system/cpu/cpu10/online
# echo 0 | sudo tee /sys/devices/system/cpu/cpu9/online
# echo 0 | sudo tee /sys/devices/system/cpu/cpu8/online
# echo 0 | sudo tee /sys/devices/system/cpu/cpu7/online
# echo 0 | sudo tee /sys/devices/system/cpu/cpu6/online
# echo 0 | sudo tee /sys/devices/system/cpu/cpu5/online
# echo 0 | sudo tee /sys/devices/system/cpu/cpu4/online
