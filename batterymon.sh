#!/bin/bash
# monitor applicaiton Battery Tempeture information by package name
function version__ {
        echo "batterymon.sh v0.1"
}

help__()
{
  echo "Usage: `basename ${0}` -d <OUTPUT_FOLDER> -s <DEVICE> -i sampleTime"
  echo "Options: These are optional argument"
  echo " -d <log out dir>"
  echo " -s <serial number> - directs command to the USB device or emulator with the given serial number"
  echo " -i Sample time, default is 1s"
  echo ""
  echo "Available devices:"
  ${ADB_CMD} devices
}

## Function : plot file
# $1 out dir
# $2 data file
# $3 y max range
function plot_file() {
    PLOT=$OUT_DIR/battery.plot
    PLOTIMAGE=$OUT_DIR/battery.png
   echo "# auto generated plot file" > $PLOT
   echo "set terminal png" >> $PLOT
   echo "set grid"  >> $PLOT
   echo "set yrange [-0.1:100]" >> $PLOT
   echo "set y2range [2.5:4.5]" >> $PLOT
   echo "unset log                              # remove any log-scaling" >> $PLOT
   echo "unset label                            # remove any previous labels" >> $PLOT
   echo "set xtic auto                          # set xtics automatically" >> $PLOT
   echo "set ytic auto                          # set ytics automatically" >> $PLOT
   echo  "set y2tic auto                          # set ytics automatically" >> $PLOT
   echo "set title 'Battery history'" >>$PLOT
   echo "set xlabel 'Time'" >> $PLOT
   echo "set ylabel 'Tempeture,Level'" >> $PLOT
     echo "set y2label 'Voltage'" >>$PLOT
   echo "set style data lines" >> $PLOT
   echo "set output '$PLOTIMAGE'" >> $PLOT
   echo "plot '$BATTERY_LOG' using 1:2 title 'Temp', '' using 1:3 title 'Level' ,   '$BATTERY_LOG' using 1:4 title 'Votage'  axis x1y2" >> $PLOT

   echo -n "Plotting $PLOT.."
   `cd $OUT_DIR && gnuplot $PLOT`
   echo "done"
}

function clean_up {
 plot_file $BATTERY_LOG
#Kill all children
  for _pid in `ps --ppid $CPULOGPID | sed '1d' | awk '{print $1}'`
  do
    if [ -n "`ps --pid $_pid | sed '1d'`" ];
    then
      kill $_pid
    fi
  done
  if [ -e $LOG_FILE ]; then
      rm $LOG_FILE
  fi
  exit 0
}


CPULOGPID=$$
adbOptions=
ADB_CMD=adb
PACKAGE_NAMES=
f_sample=4
# setup trap to catch signals
trap clean_up SIGHUP SIGINT SIGTERM SIGKILL

while getopts a:d:p:i:vs: opt
do
  case "${opt}" in
    a) ADB_CMD=${OPTARG};;
    d) OUT_DIR=${OPTARG};;
    p) PACKAGE_NAMES="${PACKAGE_NAMES} ${OPTARG}";;
    i) f_sample=${OPTARG};;
    v) version__;;
    s) adbOptions="-s ${OPTARG}";;
    \?) help__;;
  esac
done

if [ -z "${OUT_DIR}" ] ; then
  help__
  echo "Output directory:${OUT_DIR}"
  exit 1
fi
sleep 1
mkdir -p ${OUT_DIR}

DATETIME=`date +%Y%m%d%H%M%S`
LOG_FILE=${OUT_DIR}/${DATETIME}
BATTERY_FILE=${OUT_DIR}/battery_${DATETIME}
BATTERY_LOG=${OUT_DIR}/battery.txt
#echo "Time\tTemperatureVoltage\tLevel" >  ${BATTERY_LOG}

function write_batteryinfo {
    ${ADB_CMD} ${adbOptions} shell dumpsys battery > ${BATTERY_FILE}
    local Temperature=$(cat ${BATTERY_FILE}| grep temperature | awk -F:  '{ print $2 }' | tr -d [:blank:] | tr -d '\r' | tr -d '\n')
    local Voltage=$(cat ${BATTERY_FILE}| grep voltage | awk -F:  '{ print $2 }' | tr -d [:blank:] | tr -d '\r' | tr -d '\n')
    local Level=$(cat ${BATTERY_FILE}| grep level | awk -F:  '{ print $2 }' | tr -d [:blank:] | tr -d '\r' | tr -d '\n')
     local Temperature=$(echo "scale=2;$Temperature/10"| bc)
     local Voltage=$(echo "scale=2;$Voltage/1000"| bc)
    echo "$(date +%H%M%S)     ${Temperature}      ${Level}      ${Voltage}" >> ${BATTERY_LOG}
}

while true
do
  write_batteryinfo
  sleep ${f_sample}s
done

