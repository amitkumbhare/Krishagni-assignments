#!/bin/bash

echo "Enter the file we need to copy:"
read f1
echo "Enter the file to which the data will be copy:"
read f2
x=1
for((j=1;j<=$x;j++))
do
	cat $f1 >> $f2
	break
done
echo "The data copied successfully from $f1 to $f2"
