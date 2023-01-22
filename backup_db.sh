#!/bin/bash

DATE=`date +%Y-%m-%d_%H.%M.%S`
ZIPFILE=/home/varienaja/workspace/meteo/backup/meteo_dump$DATE.zip
MEASUREMENTS=`psql meteo -c "select count(*) from measurement where moment>current_timestamp-interval '24 hours';" -t`

pg_dump -c meteo | zip -9q $ZIPFILE -
SIZE=`du -sh $ZIPFILE | cut -f1`
echo "Created $ZIPFILE with $MEASUREMENTS new measurements in $SIZE."
