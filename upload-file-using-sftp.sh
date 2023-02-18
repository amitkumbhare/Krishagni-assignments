#!/bin/bash

read -p "Enter the Host name: " HOST #example "192.168.122.132"
echo "You entered $HOST"
USER="ftpuser"
PASSWORD=""

DESTINATION=$1

read -p "Enter your 1st file location: " ALL_FILES #example "DIR1/*"
echo "You entered $ALL_FILES location"

sftp -inv $HOST <<EOF
user $USER $PASSWORD
cd $DESTINATION
put $ALL_FILES
bye
EOF
