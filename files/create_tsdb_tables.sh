#!/bin/bash

export COMPRESSION="NONE"
export HBASE_HOME=/opt/hbase
export TSDB_VERSION="::TSDB_VERSION::"
export JAVA_HOME="::JAVA_HOME::"

/usr/local/share/opentsdb/tools/create_table.sh
touch /opt/opentsdb_tables_created.txt
