#!/bin/bash

if [ "$1" == "-h" ]  || [ $# -lt 4 ]; then
  echo "Usage: `basename $0` db_name admin_password user_name user_password"
  echo '    Param 1: URL of the DocumentDB instance'
  echo '             e.g. myinstance.c912049703214.us-east-2.docdb.amazonaws.com'
  echo '    Param 2: Name of the DB you want to use for application user e.g. PROD-cc'
  echo '    Param 3: MasterUserName e.g. rgadmin'
  echo '    Param 4: MasterUserPassword e.g.  rgadmin123'
  echo '    Param 5: (optional) URL for SNS Callback'
  echo '             Will use public-host-name if not passed'
  echo '             e.g. https://myrg.example.com/' 
  exit 0
fi

# If user is using DocumentDB, it also means we are not using local mongodb.
# So disable the mongod service

systemctl disable mongod
service mongod stop
myip=$(wget -q -O - http://169.254.169.254/latest/meta-data/local-ipv4)
echo "Private IP of this machine is $myip"
mydocdburl=$1
mydbname=$2
mydbuser=$3
mydbuserpwd=$4
myurl=$5
RG_HOME='/opt/deploy/sp2'

if [ -z "$myurl" ]; then
    public_host_name="$(wget -q -O - http://169.254.169.254/latest/meta-data/public-hostname)"
    baseurl="http://$public_host_name/"
else
    baseurl="$myurl/"
fi

# Modify the database to create roles and configs
echo "Modifying database $1 to create defaults"
tar -xvf /home/ubuntu/dump.tar.gz -C /home/ubuntu
mongorestore --host "$mydocdburl:27017" --noIndexRestore --ssl --sslCAFile '/opt/deploy/sp2/config/rds-combined-ca-bundle.pem' --username $mydbuser --password $mydbuserpwd "/home/ubuntu/dump/$mydbname"
mongo --ssl --host "$mydocdburl:27017" --sslCAFile '/opt/deploy/sp2/config/rds-combined-ca-bundle.pem' --username $mydbuser --password $mydbuserpwd <<EOF
use "$mydbname"
db.configs.remove({"key":"snsUrl"});
db.configs.insert({"key":"snsUrl","value":"$baseurl"});
EOF

echo "Creating mongodb.pem file"
host_name="$(wget -q -O - http://169.254.169.254/latest/meta-data/local-hostname)"
openssl genrsa -out rootCA.key 2048
openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 1024 -out RL-CA.pem -subj "/CN=."
openssl genrsa -out mongodb.key 2048
openssl req -new -key mongodb.key -out mongodb.csr -subj "/CN=$host_name"
openssl x509 -req -in mongodb.csr -CA RL-CA.pem -CAkey rootCA.key -CAcreateserial -out mongodb.crt -days 500 -sha256
cat mongodb.key mongodb.crt > /opt/deploy/sp2/config/mongodb.pem


echo "Modifying mongo-config.json file"
mytemp=`mktemp -d -p "${RG_HOME}/tmp" -t "config.old.XXX"`
echo "$mytemp"
cp "${RG_HOME}/config/mongo-config.json" "$mytemp"
cat "$mytemp/mongo-config.json" |\
        jq -r ".db_ssl_enable=true" |\
        jq -r ".db_auth_enable=true" |\
        jq -r ".db_documentdb_enable=true" |\
        jq -r ".db_ssl_config.CAFile=\"rds-combined-ca-bundle.pem\""|\
        jq -r ".db_ssl_config.PEMFile=\"mongodb.pem\""|\
        jq -r ".db_auth_config.username=\"$mydbuser\"" |\
        jq -r ".db_auth_config.password=\"$mydbuserpwd\"" |\
        jq -r ".db_auth_config.authenticateDb=\"admin\"" > "${RG_HOME}/config/mongo-config.json"

echo "Modifying docker-compose.yml file"
if [ -f "${RG_HOME}/docker-compose.yml" ]; then
      echo "docker-compose.yml exists"
      sed -i -e "s/DB_HOST=.*/DB_HOST=$mydocdburl/" "${RG_HOME}/docker-compose.yml"
      echo "Modified docker-compose.yml with DocumentDB instance URL"
fi
echo "Success"
