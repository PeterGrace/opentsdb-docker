#!/bin/sh
/opt/bin/start_hbase.sh >> /var/log/hbase.log 2>&1 &
/opt/bin/start_opentsdb.sh
