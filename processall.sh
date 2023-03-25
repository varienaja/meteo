#!/bin/bash

target=`cat target.txt`
DATE=`date +%Y-%m-%d_%H.%M.%S`
ZIPFILE="processed/archive_$DATE.zip"

for file in $target*.json
do
	./process.sh $file
	if [[ "$?" -eq "0" ]]
	then
		zip -9mqj $ZIPFILE $file
	else
		rm $file
	fi
done

if [ -f "$ZIPFILE" ]
then
	SIZE=`du -b $ZIPFILE | cut -f1`
	echo "Zipped to $SIZE bytes"
fi
