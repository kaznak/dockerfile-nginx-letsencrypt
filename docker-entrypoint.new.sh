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
$pname new [hostname...]

/etc/ssl/acme have to be persistent volume
for SSL certifications.

EOF
}

########################################################################
if [ "$#" -lt 1 ] ; then
    MSG "line:$LINENO ERROR no hostname"
    USAGE	>&3
    exit 1
fi

hosts=$@

########################################################################
MSG="line:$LINENO ERROR do not put nginx setting files."
! ls /etc/nginx/conf.d/*.conf	|
    xargs -n1 basename		|
    grep -v default.conf	|
    grep -v default_server.conf	> /dev/null

########################################################################
MSG="line:$LINENO FATAL while making acme client directory."
mkdir -p /var/www/acme /etc/ssl/acme/private

MSG="line:$LINENO ERROR while stargin nginx."
nginx

MSG="line:$LINENO ERROR while fetching SSL certifications."
for host in $hosts; do
	MSG="line:$LINENO ERROR while fetching SSL certification: $host"
	acme-client -a https://letsencrypt.org/documents/LE-SA-v1.2-November-15-2017.pdf -Nnmv $host
done

MSG="line:$LINENO ERROR while stopping nginx."
nginx -s stop

########################################################################
MSG="line:$LINENO FATAL while exiting script."
exit 0
