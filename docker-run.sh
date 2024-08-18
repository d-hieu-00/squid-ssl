#!/bin/bash
set -e

SQUID_BIN=/opt/squid/sbin/squid
SQUID_PID=/opt/squid/var/run/squid.pid
SQUID_CONF=/opt/squid/etc/squid.conf
SQUID_USER=nobody

SQUID_CERTGEN=/opt/squid/libexec/security_file_certgen
SQUID_CERTDIR=/opt/squid/ssl_db
SQUID_LOG_DIR=/opt/squid/var/logs
SQUID_LOG_FILES='/opt/squid/var/logs/access.log /opt/squid/var/logs/cache.log'

check_squid_running() {
    if pidof squid > /dev/null; then
        return 0
    else
        if [ -f $SQUID_PID ]; then
            rm $SQUID_PID -f
        fi
        return 1
    fi
}

check_tail_running() {
    if pidof tail > /dev/null; then
        return 0
    else
        return 1
    fi
}

# Set up ssl db
if [ ! -d $SQUID_CERTDIR ]; then
    $SQUID_CERTGEN -c -s $SQUID_CERTDIR -M 4MB
fi
chown $SQUID_USER:$SQUID_USER -R $SQUID_CERTDIR

# Set up log files
mkdir $SQUID_LOG_DIR -p
touch $SQUID_LOG_FILES
chown $SQUID_USER:$SQUID_USER -R $SQUID_LOG_DIR

# Check if Squid configuration file exists
if [ ! -f $SQUID_CONF ]; then
    echo "Squid configuration file not found at $SQUID_CONF"
    exit 1
fi

# Check if Squid is running and restart if necessary
if ! check_tail_running; then
    tail -q -F $SQUID_LOG_FILES &
fi

# Check if Squid is running and restart if necessary
if check_squid_running; then
    $SQUID_BIN -k reconfigure
else
    exec $SQUID_BIN -N
fi
