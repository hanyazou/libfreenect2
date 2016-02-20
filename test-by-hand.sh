#!/bin/bash

while date; do 
  echo `date "+%h %d %H:%M:%S.000"` "#### EXEC Protonect"
  ./bin/Protonect --debug_flags 253 cl
  sleep 1
  if system_profiler SPUSBDataType | grep Xbox; then
    :
  else
    echo `date "+%h %d %H:%M:%S.000"` "#### NO DEVICE"
    exit 1
  fi
done
