opentsdb-docker
===============

Files required to make a trusted opentsdb Docker such that opentsdb can be used for other projects (e.g. scollector, bosun)

How it works
============
This image automatically starts HBase, waits 30 seconds, then attempts to create the opentsdb tables in hbase and then fires up opentsdb.  Make sure that
you export port 4242 so that you can access opentsdb outside of the container.


Notes
=====
  - This image has a VOLUME declaration -- if you want to persist your hbase data, use the `-v` argument in docker to store hbase data on local filesystem. Use:
    ``` docker run -p 4242:4242 -v /data/hbase:/data/hbase -v /tmp:/data/tmp  ```
  - This image has port 16010 exported so that you can use scollector to collect hadoop statistics.
