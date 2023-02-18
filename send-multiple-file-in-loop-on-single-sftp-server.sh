#!/bin/bash
#------------------------------To send multiple file in loop on single sftp server-----------------------------

#Getting vaiable for login details :
USER="asta"
HOST="192.168.122.15"

#find all files in "Parent" folder, then put the values in "NS" variable. : 
NS=( $(find krishagni/ -type f -name "*") )

#counting the length of NS variables :
len=${#NS[@]}

#Then created a loop for getting each value from "len" variable :
for (( i=0; i<$len; i++ ));
do
	#Apply if to find that if "len" variable is greater than 0 : 
	if [ "$len" -gt "0" ]
	then
		#if yes then this statement will print : 
		echo "put ${NS[$i]} ${NS[$i]}"
	fi 

	#now with the help of pipe "|" to get the output of above echo command in inside the sftp command and it will run the sftp command and put the files in belonging destonation : 
done | sftp $USER@$HOST
