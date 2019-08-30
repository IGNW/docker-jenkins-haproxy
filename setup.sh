#!/bin/bash

# Persistent storage for containers:
STORAGE_DIR="/opt/jenkins-haproxy"

# Download docker-compose

echo "download docker-compose to /usr/local/bin/docker-compose"
sudo curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod 755 /usr/local/bin/docker-compose

# Certificate specific variables:
COUNTRY="US"
STATE="WA"
LOCATION="nowhere"
ORGANIZATION="NA"
ORG_UNIT="IT"
COMMON_NAME="*.example.local"


echo "This script will run as sudo ..."
echo

echo "Creating directory structure under ${STORAGE_DIR}"
echo
sudo mkdir -p ${STORAGE_DIR}/{haproxy,jenkins}
sudo mkdir -p ${STORAGE_DIR}/jenkins/jenkins_home

#tree -L 3 -d ${STORAGE_DIR}

sudo chown 1000:1000 ${STORAGE_DIR} -R

echo
echo "Creating self signed certificates in /tmp - in non-interactive mode ..."
echo
# http://crohr.me/journal/2014/generate-self-signed-ssl-certificate-without-prompt-noninteractive-mode.html
openssl genrsa -des3 -passout pass:x -out /tmp/server.pass.key 2048
openssl rsa -passin pass:x -in /tmp/server.pass.key -out /tmp/server.key
rm /tmp/server.pass.key 
openssl req -new -key /tmp/server.key -out /tmp/server.csr \
  -subj "/C=${COUNTRY}/ST=${STATE}/L=${LOCATION}/O=${ORGANIZATION}/OU=${ORG_UNIT}/CN=${COMMON_NAME}"
openssl x509 -req -days 365 -in /tmp/server.csr -signkey /tmp/server.key -out /tmp/server.crt

# Combine /tmp/server.key and /tmp/server.crt into a single server.pem file. 

echo
echo "Creating a combined certificate and saving it as ${STORAGE_DIR}/haproxy/haproxy.pem"
cat /tmp/server.crt /tmp/server.key > ${STORAGE_DIR}/haproxy/haproxy.pem
echo

echo "Copy haproxy.cfg to ${STORAGE_DIR}/haproxy/" 
# The certs are self signed (for example.com), so not a problem if they exist in the repo. 
cp haproxy/haproxy.cfg ${STORAGE_DIR}/haproxy/
echo
echo "Done."
echo
echo "You can start the application suite using docker-compose up -d"
echo
echo
echo "After you start the containers cat this file to get the initial password"
echo
echo "cat /opt/jenkins-haproxy/jenkins/jenkins_home/secrets/initialAdminPassword" 
echo

