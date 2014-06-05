#!/bin/bash
export JAVA_HOME=/usr/lib/jvm/java-6-openjdk-amd64
echo "127.0.0.1 localhost $(hostname)" > /etc/hosts
trap "echo stopping hbase;/opt/hbase/bin/hbase master stop>>/var/log/hbase-stop.log 2>&1; exit" HUP INT TERM EXIT
echo "starting hbase"
/opt/hbase/bin/hbase master start >> /var/log/hbase-start.log 2>&1 &
while true
do
  sleep 1
done
