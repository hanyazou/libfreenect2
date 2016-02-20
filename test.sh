#!/bin/bash

show_env()
{
    date
    uname -a
    system_profiler SPSoftwareDataType
    env
    echo ----------
    echo '$' cat $0
    cat $0
    echo ----------
    echo '$ git log'
    git log | head -6
    echo '$ git diff'
    git diff | cat
    echo ----------
}

expand()
{
    local pattern='\([0-9]*\)\(-\([0-9]*\)\)*\(,\([0-9]*\)\)*'
    local i
    local j

    for i in $*; do
        local start=`echo "$i" | sed "s/$pattern/\1/"`
        local end=`echo "$i" | sed "s/$pattern/\3/"`
        local step=`echo "$i" | sed "s/$pattern/\5/"`
        if [ "$step". == . ]; then
            step=1
        fi
        if [ "$end". == . ]; then
            echo $i
        else
            j=$start
            while [ $j -le $end ]; do
                echo $j
                let "j += $step"
            done
        fi
    done
}

reset()
{
    echo "#### RESET"
    ./bin/Protonect --force_reset_all_devices --exit
    sleep 5
}

error_detected()
{
    echo "#### ERROR"
    let "error = $error + 1"
    reset
}

test()
{
    date
    echo $*
    #$* > output 2>&1 &
    $* 2>&1 &
    pid=$!
    wait=$((RANDOM % 3 + 4)).$((RANDOM % 100))
    echo sleep $wait
    sleep $wait
    #kill -KILL $pid
    #kill -INT $pid || tail output
    kill -INT $pid || error_detected
    ( sleep 10; kill $pid ) &
    killer_pid=$!
    wait $pid
    kill $killer_pid || error_detected
    sleep 1
    if system_profiler SPUSBDataType | grep Xbox; then
	:
    else
	echo "#### NO DEVICE"
	sleep 4 # wait for the device back
        let "reboot = $reboot + 1"
    fi
}

try=500
try=100
skip="153 154 185 253"
skip="153 154 253 158 159 160 162"
exits="1 10 101 102 103 104 105 106 107 108 109 110 111 112 113 20 201 202 203 204 205 206 207 208 209"
exits="1001-1099 1100-1199,2 1200-1500,5"
exits="2001-2199,1"
exits="1001-1099,2"
skip="253"
exits="999"
exits=`expand $exits`

for exit in $exits; do
  eval "reboot$exit=?"
  eval "error$exit=?"
done

LOG_FILE=`dirname $0`/test-logs/`basename $0`-`date '+%Y%m%d-%H%M%S'`.txt
{
echo log file is $LOG_FILE
show_env
reset
start_time=`date '+%s'`
progress=0
all=0
for j in $exits; do
  let "all = $all + 1"
done
let "all = $all * $try"
for exit in $exits; do
  i=0
  reboot=0
  error=0
  while [ $i -lt $try ]; do
    #test ./bin/Protonect --debug_flags $skip $exit cl -noviewer
    test ./bin/Protonect --debug_flags $skip $exit cl 
    let "i = $i + 1"
    let "progress = $progress + 1"
    eval "reboot$exit=$reboot"
    eval "error$exit=$error"
    echo ===================================
    for j in $exits; do
      eval "t=\$reboot$j"
      if [ $t. != '?.' ]; then
        eval "printf \"%4d: %4d / %-4d err=%-4d \" $j \$reboot$j $try \$error$j"
	eval "let \"rate = \$reboot$j * 50 / $try\""
        rate_s=`printf "%${rate}s" | tr " " "*"`
	printf "|%-50s|\n" "$rate_s"
      fi
    done
    let "cur_time = `date '+%s'` - $start_time"
    let "est_end_time = $cur_time * $all / $progress"
    echo
    echo "skip=$skip, exit at $exit"
    printf "#### %6d / %-6d : " $progress $all
    printf "%2dh%02dm / %2dh%02dm " $(($cur_time / 3600)) $(($cur_time / 60 % 60 )) $(($est_end_time / 3600)) $(($est_end_time / 60 % 60))
    printf "(%3d%%) " $(($progress * 100 / $all))
    printf "\n"
    echo ===================================
  done
done

} 2>&1 | tee ${LOG_FILE}
