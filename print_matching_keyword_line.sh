#!/bin/bash

echo "Enter a keyword to search in the student file:"
read keyword

if grep -q "$keyword" student
then
    echo "The following lines match the keyword '$keyword':"
    grep "$keyword" student
else
    echo "No match found for the keyword '$keyword'."
fi

