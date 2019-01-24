::编码UTF-8
CHCP 65001
@echo off
::传入运行时间，此项根据需要修改，单位分钟
set runTime=1
::传入运行包名，此项根据需要修改，全包名
set packageName=com.jifen.qukan
echo 您指定的运行的时间：%runTime% 分钟
echo 您指定的运行的包：%packageName%
echo 开始push所需配置文件至手机。。。
echo push monkey.jar
adb push  config/monkey.jar /sdcard/
echo push framework.jar
adb push  config/framework.jar /sdcard/
echo push max.config
adb push  config/max.config /sdcard/
echo 开始执行测试脚本，请勿关闭窗口。。。
adb shell "CLASSPATH=/sdcard/monkey.jar:/sdcard/framework.jar exec app_process /system/bin tv.panda.test.monkey.Monkey -p %packageName% --uiautomatormix --running-minutes %runTime% -v -v --imagepolling   --output-directory /sdcard/maxim_log/ >/sdcard/monkeyout.txt 2>/sdcard/monkeyerr.txt"
echo 执行完毕,手机上maxim日志的路径：/sdcard/maxim_log

set ymd=%date:~3,4%%date:~8,2%%date:~11,2%
set hms=%time:~0,2%%time:~3,2%%time:~6,2%%time:~9,2%
set dt=%ymd%%hms%

::创建结果文件夹

if exist result (echo result文件夹已经存在，无需创建。) else ( echo 创建result文件夹  md result )
cd result
echo 根据当前时间创建的文件夹：%dt%

md %dt%
cd %dt%
md maxim_log
cd ../../

echo 正在将日志拉取到电脑上

adb pull   /sdcard/maxim_log/  result/%dt%/maxim_log
adb pull   /sdcard/monkeyout.txt  result/%dt%
adb pull   /sdcard/monkeyerr.txt result/%dt%
echo 本地日志存储文件夹：result/%dt%
echo 日志拉取完毕

pause
