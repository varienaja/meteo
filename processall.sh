#!/bin/bash

target=`cat target.txt`
DATE=`date +%Y-%m-%d_%H.%M.%S`
ZIPFILE="processed/archive_$DATE.zip"

for file in $target*.json
do
  ./process.sh $file
  if [ -f "$file" ]
  then
    zip -9mqj $ZIPFILE $file
  fi
done

SIZE=`du -b $ZIPFILE | cut -f1`
echo "Zipped to $SIZE bytes"

