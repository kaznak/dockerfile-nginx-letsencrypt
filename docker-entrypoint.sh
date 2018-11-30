
if [ ! "$HOSTS" ] ; then
    echo "INFO Environment variable $HOSTS is not set. set www.example.com for example."	>&2
   HOSTS="www.example.com"
fi

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

/etc/periodic/weekly/acme-client

exec "$@"
