#!/bin/bash

cd /home/varienaja/workspace/meteo/
./download.sh
./processall.sh
./interpolate.sh
cd ~-
