#!/bin/bash

# Processes a json in parameter 1

TYPE=`jq -r '.stations | .[0] | .network' $1`
if [ "$TYPE" = "" ]
then
  echo "Could not extract type from $1"
fi
UNIT=`jq -r '.headers | .[2] | .unit' $1` 

tmpfile=$(mktemp /tmp/meteo.sql.XXXXXX)

echo "insert into sensor (code, network, name, unit) values" >> $tmpfile
jq -r '.stations | .[] | (.id + " " + .current.value + " " + (.current.date|tostring) +" " + .altitude + " " + .station_name + " " )' $1 | while read ID VAL t HEIGHT NAME; do 
	NAMEE=`echo "$NAME" | sed "s/'/''/g"`
	echo "('$ID', '$TYPE', '$NAMEE', '$UNIT')," >> $tmpfile
done
echo "('dummy', 'dummy', 'dummy', '') on conflict do nothing; " >> $tmpfile #Dummy value will be skipped anyway



echo "insert into measurement (sensor_id, moment, value) values" >> $tmpfile
jq -r '.stations | .[] | (.id + " " + .current.value + " " + (.current.date|tostring) +" " + .altitude + " " + .station_name + " " )' $1 | while read ID TEMP t HEIGHT NAME; do
	DATE=`date -d @$( echo "$t/1000" | bc) "+%Y-%m-%d %H:%M:%S"`
	echo "((select id from sensor where code='$ID' and network='$TYPE'), '$DATE', $TEMP)," >> $tmpfile
done
echo "(null, '1970-01-01 00:00', null) on conflict do nothing; " >> $tmpfile #Dummy value will be skipped anyway

#cat $tmpfile
RESULT=`cat $tmpfile | psql meteo` # INSERT 0 0 OR INSERT 0 169
DATE=`date "+%Y-%m-%d %H:%M:%S"`
echo $RESULT | (read d e f a b c; c=`echo "$c-1" | bc`; echo "$DATE Processed $c values for $TYPE")
#if [ $c -eq 0 ]
#then
#  echo "nothign new"
#  rm $1
#fi

rm $tmpfile
