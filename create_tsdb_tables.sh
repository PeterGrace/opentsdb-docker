
#!/bin/bash

export COMPRESSION="NONE"
export HBASE_HOME=/opt/hbase
export JAVA_HOME=/usr/lib/jvm/java-6-openjdk-amd64

cd /opt/opentsdb/opentsdb-2.1.3/
./src/create_table.sh
touch /opt/opentsdb_tables_created.txt
