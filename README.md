# BatteryMonitor

##  Description

The project is for monitoring battery voltage, tempeture and battery level which is by "adb shell dumpsys battery"

## Script requires
Ubuntu

gnuplot

you should install by "sudo apt-get install gnuplot"

## How to use

batterymon.sh -d Result -s 192.168.1.2:5555 -i 10


## WiFi ADB

for monitor charging,  you can open wifi or from data, so you should know your phone IP address first

then connect to listen the port

adb tcpip 5555

adb connect IP:5555


