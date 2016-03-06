#!/bin/bash

if [ "$*". != . ]; then
    tgts="$*"
else
  logdir=`dirname $0`/test-logs
  tgts=`ls -tr $logdir/test.sh-*.txt | tail -1`
fi

doit()
{
cat $1 | awk '
BEGIN {
  idx=0;
  bs=5;
  ok=0;
}
/^#### OK/ {
  if (ok != 1) {
    last_ok="";
    print;
  } else {
    last_ok=$0;
  }
  ok=1;
  next;
}
{
  ok=0;
  buf[idx++] = $0;
  if (bs < idx)
    idx = 0;
}
/^#### / {
  for (i = 0; i < bs; i++) {
    printf("%s\n", buf[(idx+i)%bs]);
  }
}
END {
  if (last_ok != "")
    print last_ok;
}
'
}

for tgt in $tgts; do
  doit $tgt
done
