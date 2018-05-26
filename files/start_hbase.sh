#!/bin/bash
export JAVA_HOME="::JAVA_HOME::"
export PATH="::PATH::"
trap "echo stopping hbase;/opt/hbase/bin/hbase master stop>>/var/log/hbase-stop.log 2>&1; exit" HUP INT TERM EXIT
echo "starting hbase"
/opt/hbase/bin/hbase master start
