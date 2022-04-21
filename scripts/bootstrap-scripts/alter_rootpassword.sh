#!/bin/bash
sleep 60s
root_password=$1
docker exec docker_mysql mysql -u root -p"$root_password" -Bse "ALTER USER 'root'@'%' IDENTIFIED WITH mysql_native_password BY '${root_password}'; FLUSH PRIVILEGES;"
