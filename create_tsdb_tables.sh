
#!/bin/bash

export COMPRESSION="NONE"
export HBASE_HOME=/opt/hbase
export JAVA_HOME=/usr/lib/jvm/java-6-openjdk-amd64

cd /opt/opentsdb
./src/create_table.sh
touch /opt/opentsdb_tables_created.txt
