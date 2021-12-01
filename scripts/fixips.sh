#!/bin/bash
version="0.1.4"
echo "Fixing IPs....(fixips.sh v$version)"

#Find out the IP address of eth0
myip=`hostname -I | awk '{print $1}'`

[ -z $myip ] && echo 'Cannot determine private IP. Exiting with error.' && exit 1

echo "my IPAddress is $myip"

# Fix the bind address in /etc/mongod.conf
if [ -f /etc/mongod.conf ]; then
	echo "mongod.conf exists"
	sed -i -e "s/bindIp:.*/bindIp: $myip/" /etc/mongod.conf
	cat /etc/mongod.conf | grep -e 'bindIp'
        systemctl enable mongod
	echo "Restarting MongoD"
	service mongod restart
fi


## Fix the bind address in /etc/redis/redis.conf
#if [ -f /etc/redis/redis.conf ]; then
#	echo "redis.conf exists"
#	sed -i -e "s/^bind.*/bind $myip /" /etc/redis/redis.conf
#        cat /etc/redis/redis.conf | grep -e '^bind'
#        systemctl enable redis-server
#	echo "Restarting Redis"
#	service redis-server restart
#fi
#echo "Waiting 30s for services to restart"
sleep 30
service mongod status
#service redis-server status

