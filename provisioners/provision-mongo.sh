apt-get update -y
apt-get install gnupg -y
wget -qO - https://www.mongodb.org/static/pgp/server-${MONGO_VERSION}.asc | apt-key add -
touch /etc/apt/sources.list.d/mongodb-org-${MONGO_VERSION}.list
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/${MONGO_VERSION} multiverse" | tee /etc/apt/sources.list.d/mongodb-org-${MONGO_VERSION}.list
apt-get update -y
apt-get install -y mongodb-org
cp /tmp/mongod.conf /etc/mongod.conf
