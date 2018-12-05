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
# set -vx

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
if [ "$#" -lt 1 ] ; then
    MSG "line:$LINENO ERROR no hostname"
    USAGE	>&3
    exit 1
fi

hosts=$@

########################################################################
MSG="line:$LINENO FATAL while checking nginx site configuration."
error=0
for host in $hosts ; do
    if [ -s /etc/nginx/conf.d/$host.conf ] ; then
	MSG line:$LINENO ERROR no nginx site configuration file: $host
	error=1
    fi
done
MSG="line:$LINENO ERROR insuffisient site configuration."
[ "$error" -eq 0 ]

########################################################################
MSG="line:$LINENO INFO while Generating acme-client periodic script"
cat	<<EOF	> /etc/periodic/weekly/acme-client
#!/bin/sh

for host in $hosts ; do
        acme-client -a https://letsencrypt.org/documents/LE-SA-v1.2-November-15-2017.pdf -Nnmv \$host && renew=1
done

[ "\$renew" = 1 ] && nginx -s reload
EOF

MSG="line:$LINENO INFO while Generating initial certficate"
/etc/periodic/weekly/acme-client

########################################################################
MSG="line:$LINENO FATAL while executing nginx"
exec nginx -g "daemon off;"
