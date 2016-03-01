#!/bin/bash
all=1000
error=0
timeout=0
show_stat()
{
    let "progress = $progress + 1"
    let "ct = `date '+%s'` - $st"
    let "et = $ct * $all / $progress"
    
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
error_detected()
{
    error=$(($error + 1))
    if [ "$detected". != . ]; then return; fi
    detected=1
    cat $out
    show_stat "#### EXIT" $*
    sleep 5
}
timeout_detected()
{
    timeout=$(($timeout + 1))
    if [ "$detected". != . ]; then return; fi
    detected=1
    cat $out
    show_stat "#### TIMEOUT"
}
echo log file is $LOG_FILE
LOG_FILE=`dirname $0`/test-logs/`basename $0`-`date '+%Y%m%d-%H%M%S'`.txt
{
show_env
st=`date '+%s'`
progress=0
out=/tmp/protonect-out
for i in `seq 1 $all`; do
    detected=
    ./bin/Protonect cl -frames 1 > $out 2>&1 &
    protonect_pid=$!
    ( sleep 20; kill -15 $protonect_pid ) > /dev/null 2>&1 &
    killer_pid=$!
    wait $protonect_pid
    exit_stat=$?
    if [ $exit_stat != 0 -a $exit_stat != 143 ]; then
	error_detected `printf "%2x" $exit_stat`
    fi
    ps $killer_pid > /dev/null 2>&1 || timeout_detected
    if grep timeout $out; then
	timeout_detected
    fi
    if [ "$detected". != . ]; then
	:
    else
        show_stat "#### OK"
    fi
done
} 2>&1 | tee ${LOG_FILE}
