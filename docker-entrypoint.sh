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
{
    set +u
    if [ ! "$HOSTS" ] ; then
	MSG "line:$LINENO INFO Environment variable $HOSTS is not set. set www.example.com for example."	>&2
	HOSTS="www.example.com"
    fi
    set -u
}

########################################################################
if ls /etc/nginx/conf.d/*.conf|grep -qv /etc/nginx/conf.d/default_server.conf|grep -qv /etc/nginx/conf.d/default.conf ; then
    ################################################################
    # Run command
    MSG="line:$LINENO FATAL while Cleaning up"
    shopt -u nullglob
    BEFORE_EXIT

    MSG="line:$LINENO FATAL while executing"
    exec "$@"
else
    MSG="line:$LINENO INFO while Generating acme-client periodic script"
    {
	cat	<<EOF	> /etc/periodic/weekly/acme-client
#!/bin/sh

hosts="$HOSTS"

for host in \$hosts; do
        acme-client -a https://letsencrypt.org/documents/LE-SA-v1.2-November-15-2017.pdf -Nnmv \$host && renew=1
done

[ "\$renew" = 1 ] && nginx -s reload
EOF

	unset HOSTS

	chmod +x /etc/periodic/weekly/acme-client

	MSG="line:$LINENO INFO while starting nginx"
	nginx

	MSG="line:$LINENO INFO while Generating initial certficate"
	/etc/periodic/weekly/acme-client

	MSG="line:$LINENO INFO while stopping nginx"
	nginx -s stop
    }

    ################################################################
    # Run command
    MSG="line:$LINENO FATAL while exit"
    shopt -u nullglob
    exit 0
fi
