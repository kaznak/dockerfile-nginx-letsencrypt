#!/bin/bash

set -Cu
set -Ee
set -o pipefail
shopt -s nullglob

based=$(dirname $0)/..
pname=$(basename $0)
stime=$(date +%Y%m%d%H%M%S%Z)

exec 3>&2
# logd=$based/log
# exec 3>&2 2>$logd/$pname.$stime.$$.log
set -vx

MSG() {
    echo "$pname pid:$$ stime:$stime etime:$(date +%Y%m%d%H%M%S%Z) $@"	>&3
}

tmpd=$(mktemp -d -t "$pname.$stime.$$.XXXXXXXX")/
if [ 0 -ne "$?" ] ; then
    MSG FATAL can not make temporally directory.
    exit 1
fi

trap 'BEFORE_EXIT' EXIT
BEFORE_EXIT()	{
    rm -rf $tmpd
}

trap 'ERROR_HANDLER' ERR
export MSG
ERROR_HANDLER()	{
    [ "$MSG" ] && MSG $MSG
    touch $tmpd/ERROR	# for child process error detection
    exit 1		# root process trigger BEFORE_EXIT function
}

########################################################################
USAGE() {
    cat	<<EOF
$pname [new|run] [hostname...]

commands:
  help : show this message
  new : fetch initical SSL certificate
	/etc/ssl/acme have to be persistent volume
	for SSL certifications.
  run : run nginx server
EOF
}

########################################################################
if [ "$#" -eq 1 -a "$1" = "help" ] ; then
    USAGE
    exit 0
fi

if [ "$#" -lt 2 -o "$1" != "new" -o "$1" != "run" ] ; then
    USAGE	>&3
    exit 1
fi

command=$1
shift

########################################################################
exec docker-entrypoint.$command.sh $@
