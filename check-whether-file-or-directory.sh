#!/bin/bash

for x in $*
do
	if [[ -f $x ]]
	then
		echo "$x is a file."
		echo "no of line in $x file are: "
		wc -l $x 
		NO=`wc -l $x`
		read lineno
		if [[ $NO > $lineno ]]
		then
			head -n $lineno	$x
		else
			echo "Range Excided."
		fi
	elif [[ -d $x ]]
	then
		echo "$x is a directory."
	else
		echo "enter vaild file name or directory."
	fi
done
