#!/bin/bash

date +'%A'
day=`date +'%A'`
if [ "$day" == Sunday ]
then
	echo "Its still Week-End."
elif [ "$day" == Saturday ]
then
	echo "Week-End stated."
else
	echo "Its Working Day."
fi
