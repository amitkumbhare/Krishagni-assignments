#!/bin/bash

echo -n "Enter First number: "
read var1

echo -n "Enter Second number: "
read var2

echo -n "Enter Third number: "
read var3

if [[ $var1 -ge $var2 ]]
then
	if [[ $var1 -ge $var3 ]]
	then
		echo "$var1 is largest number."
	else
		echo "$var3 is largest number."
	fi
else
	if [[ $var2 -ge $var3 ]]
	then
		echo "$var2 is largest number."
	else
		echo "$var3 is largest number."
	fi
fi
