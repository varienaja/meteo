#!/bin/bash

target=`cat target.txt`

while read filename; do
	 wget -q -P "$target" "$filename"
done < urls.txt
