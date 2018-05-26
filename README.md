# opentsdb-docker

Files required to make a trusted opentsdb Docker such that opentsdb can be used for other projects (e.g. scollector, bosun)

## How it works
This image automatically starts HBase, waits a configurable number of  seconds, then 
attempts to create the opentsdb tables in hbase and then fires up opentsdb.  
Make sure that you export port 4242 so that you can access opentsdb outside of the container.

## Usage

### "I just want to play with opentsdb as soon as possible!"
`docker run -dp 4242:4242 petergrace/opentsdb-docker`

### "I want my data to persist even if the container is deleted!"
Use the supplied docker-compose.yml file to start the container.  Data will be persisted in ./data

`docker-compose up -d`

**NOTE: When stopping the container, please use the -t option to give more time for hbase to shutdown, 
otherwise data corruption may result.  At least 30 seconds is suggested.**

Example: `docker-compose stop -t 30`

### I want to use my own opentsdb.conf file!
You can volume-mount it into the docker container at /etc/opentsdb/opentsdb.conf.  If entrypoint.sh 
already sees a file there it will not copy over the default.

### I want to use my own hbase-site.xml file!
Similarly to the opentsdb.conf file, volume-mount your version at /opt/hbase/conf/hbase-site.xml.

### I want to use specific opentsdb plugins!
Volume-mount the plugins into /opentsdb-plugins (most people wont be using these)
