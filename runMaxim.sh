#!/bin/bash

#app的包名
packageName="com.xueqiu.android"
#运行时间，正式使用时需要修改。单位为分钟
runTime=2
#需要指定的手机序列号，如果电脑就插了一部手机，可以不填，会自动检测
serial=$1
#事件间隔，单位毫秒，如果小于等于200，则不会生成截图
throttle=200

adb devices
if [ ! -n "$serial" ]; then
    serial=$(adb devices | grep -w 'device' | head -n 1 | awk '{print $1}')
    echo "test"
    if [ "$?" -ne 0 ] ; then
        serial="00000"
    fi
else
    echo "use default devices: $serial"
fi

echo "use device: $serial"
devices=" -s $serial "


rel_serial=`adb $devices shell getprop ro.serialno | head -n 1 | grep -oE "[0-9a-zA-Z]+"`

#CURRENT_TIME="$serial-$tt"
CURRENT_TIME=`date +%Y%m%d%H%M%S`

echo "You set test time: "$runTime" m."
echo "You set test packageName: "$packageName"."

device=$(adb devices | grep -w 'device' | grep $serial)
if [ "$?" -ne 0 ] ; then
    echo "no devices/emulators found"
    exit
fi

echo "start upload config files."

#上传jar和配置文件
adb $devices push  config/monkey.jar /sdcard/
adb $devices push  config/framework.jar /sdcard/
adb $devices push  config/max.config /sdcard/

#将手机的日志拉到本地
if [ ! -d "./result" ]; then
  echo "result not found,start create result folder!"
  mkdir result
else
  echo "result exist."
fi

cd result/

#手机上存放log的路径
outputDirName=maxim-$CURRENT_TIME
outputDir=/sdcard/$outputDirName/


if [ ! -d "./"$CURRENT_TIME ]; then
    echo "create a storage folder with the current timestamp as the folder name:"$CURRENT_TIME"."
    mkdir $CURRENT_TIME
fi

resDir=./"$CURRENT_TIME/$rel_serial"
mkdir -p $resDir
echo "target result dir is : $resDir"
#exit
echo $rel_serial > $resDir/deviceName.txt

echo "start execute test."
adb $devices shell logcat -c
adb $devices shell logcat -v threadtime > $resDir/logcat.txt 2>&1  &

nohup adb $devices shell CLASSPATH=/sdcard/monkey.jar:/sdcard/framework.jar exec app_process /system/bin tv.panda.test.monkey.Monkey -p $packageName --uiautomatormix --running-minutes $runTime --throttle $throttle -v -v --imagepolling --output-directory $outputDir >$resDir/monkeyout.txt 2>$resDir/monkeyerr.txt &

sleep 8

isPS_EF=$(adb $devices shell ps -ef | wc -l)
ef=""
if [ $isPS_EF -gt 1 ]; then
    ef=" -ef "
    echo "use -ef "
fi

while [ "$device" ]
do
# 获取PID，uid, 防止APP重启


    PID=$(adb $devices shell ps $ef | grep "$packageName" | grep -v "$packageName:" | awk '{print $2}')
    echo "PID:"$PID
    #ps -ef | grep "uiautomatormix"
    FLAG=`ps -ef | grep "uiautomatormix" | grep "$serial" | wc -l`
    #echo "FLAG=$FLAG"
    if [ $FLAG -lt 1 ]; then
        ps -ef | grep "uiautomatormix"
        echo "device:$serial will stop";
        ps -ef | grep "$serial shell logcat -v" | awk '{print $2}' | xargs kill
        break;
    fi

    if [ -n "$PID" ]; then
      echo $PID >> $resDir/pid.txt
    fi
    while [ !  -n "$PID" ]
    do
    echo "retry to get PID"
    FLAG=`ps -ef | grep "uiautomatormix" | grep "$serial" | wc -l`
    if [ $FLAG -lt 1 ]; then
        ps -ef | grep "uiautomatormix"
        echo "device:$serial will stop 2";
        ps -ef | grep "$serial shell logcat -v" | awk '{print $2}' | xargs kill
        break;
    fi
    PID=$(adb $devices shell ps $ef | grep "$packageName" | grep -v "$packageName:" | awk '{print $2}')
    echo "PID:"$PID
    if [ -n "$PID" ]; then
      echo $PID >> $resDir/pid.txt
    fi
    sleep 5
    done
    sleep 5

done

adb $devices pull $outputDir $resDir/maxim_log
echo "maxim log pull finished!"
