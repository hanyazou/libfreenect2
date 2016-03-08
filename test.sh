#!/bin/bash
all=10000
error=0
timeout=0
show_stat()
{
    ct=$((`date '+%s'` - $st))
    et=$(($ct * $all / $progress))
    
    printf "%-13s %s" "$*" "`date '+%b %d %H:%M:%S'`"
    printf " timeout=%d error=%d " $timeout $error
    printf " %dh%02dm%02ds" $(($ct / 3600)) $(($ct / 60 % 60)) $(($ct % 60))
    printf "/%dh%02dm%02ds" $(($et / 3600)) $(($et / 60 % 60)) $(($et % 60))
    printf " %d (%d%%)" $progress $(($progress * 100 / $all))
    printf "\n"
}
show_env()
{
    echo `system_profiler SPSoftwareDataType | grep "OS X" || uname -a`
    git log -1 --oneline
    git diff | cat
}
shutdown_detected()
{
    shutdown=$(($shutdown + 1))
    if [ "$detected". = . ]; then
	cat $out | tr -d '\0'
	detected=1
    fi
    show_stat "#### SHUTDOWN"
    sleep 5
}
error_detected()
{
    error=$(($error + 1))
    if [ "$detected". = . ]; then
	cat $out | tr -d '\0'
	detected=1
    fi
    show_stat "#### EXIT" $*
}
timeout_detected()
{
    timeout=$(($timeout + 1))
    if [ "$detected". = . ]; then
	cat $out | tr -d '\0'
	detected=1
    fi
    tr -d '\0' < $out | grep timeout
    show_stat "#### TIMEOUT"
}
check_device()
{
    if (ioreg -p IOUSB || lsusb -d 045e:02c4 -v) 2>&1 | grep -i xbox > /dev/null; then
	:
    else
	return 1
    fi
    sleep 1
    if (ioreg -p IOUSB || lsusb -d 045e:02c4 -v) 2>&1 | grep -i xbox > /dev/null; then
	return 0
    else
	return 1
    fi
}
LOG_FILE=`dirname $0`/test-logs/`basename $0`-`date '+%Y%m%d-%H%M%S'`.txt
echo log file is $LOG_FILE
{
show_env
st=`date '+%s'`
progress=0
out=/tmp/protonect-out
for i in `seq 1 $all`; do
    detected=
    ./bin/Protonect cl -frames 1 > $out 2>&1 &
    protonect_pid=$!
    progress=$(($progress + 1))
    ( sleep 50; kill -15 $protonect_pid ) > /dev/null 2>&1 &
    killer_pid=$!
    wait $protonect_pid
    exit_stat=$?
    ps $killer_pid > /dev/null 2>&1 || timeout_detected
    if [ $exit_stat != 0 ]; then
	error_detected `printf "%2x" $exit_stat`
    fi
    if check_device; then
	:
    else
	shutdown_detected
    fi
    if tr -d '\0' < $out | grep timeout > /dev/null; then
	timeout_detected
    fi
    if [ "$detected". != . ]; then
	:
    else
        show_stat "#### OK"
    fi
done
} 2>&1 | tee ${LOG_FILE}
