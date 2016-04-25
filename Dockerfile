FROM ubuntu

RUN apt-get -yq update

RUN apt-get -yq install make wget autoconf default-jdk unzip gnuplot


#RUN apk --update add rsyslog bash openjdk7 make wget unzip
#
#RUN apk --update add --virtual builddeps build-base autoconf automake git python
#
ENV TSDB_VERSION 2.2.0
ENV HBASE_VERSION 1.1.4
ENV JAVA_HOME /usr/lib/jvm/default-java
ENV PATH $PATH:/usr/lib/jvm/default-java/bin/
#
RUN mkdir -p /opt/bin/
#
RUN mkdir /opt/opentsdb/
WORKDIR /opt/opentsdb/

##Install OpenTSDB and scripts
RUN wget --no-check-certificate -O v${TSDB_VERSION}.zip https://github.com/OpenTSDB/opentsdb/archive/v${TSDB_VERSION}.zip && \
    unzip v${TSDB_VERSION}.zip && \
    rm v${TSDB_VERSION}.zip
WORKDIR /opt/opentsdb/opentsdb-${TSDB_VERSION}
RUN ./build.sh


##Install HBase and scripts
RUN mkdir -p /data/hbase
RUN mkdir -p /root/.profile.d
RUN mkdir -p /opt/downloads
WORKDIR /opt/downloads
RUN wget -O hbase-${HBASE_VERSION}.bin.tar.gz http://www-us.apache.org/dist/hbase/1.1.4/hbase-1.1.4-bin.tar.gz && \
    tar xzvf hbase-${HBASE_VERSION}.bin.tar.gz && \
    mv hbase-${HBASE_VERSION} /opt/hbase && \
    rm hbase-${HBASE_VERSION}.bin.tar.gz
#
ADD docker/hbase-site.xml /opt/hbase/conf/
ADD docker/start_opentsdb.sh /opt/bin/
ADD docker/create_tsdb_tables.sh /opt/bin/
ADD docker/start_hbase.sh /opt/bin/

RUN for i in /opt/bin/start_hbase.sh /opt/bin/start_opentsdb.sh /opt/bin/create_tsdb_tables.sh; \
    do \
        sed -i "s#::JAVA_HOME::#$JAVA_HOME#g; s#::PATH::#$PATH#g; s#::TSDB_VERSION::#$TSDB_VERSION#g;" $i; \
    done

RUN mkdir -p /etc/services.d/hbase /etc/services.d/tsdb
RUN ln -s /opt/bin/start_hbase.sh /etc/services.d/hbase/run
RUN ln -s /opt/bin/start_opentsdb.sh /etc/services.d/tsdb/run


EXPOSE 60000 60010 60030 4242 16010

VOLUME ["/data/hbase"]

ENTRYPOINT /opt/bin/start_hbase.sh & /opt/bin/start_opentsdb.sh
