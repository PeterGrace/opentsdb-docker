FROM janeczku/alpine-kubernetes:3.2

RUN apk --update add \
    rsyslog \
    bash \
    openjdk7 \
    make \
    wget \
  && : adding gnuplot for graphing \
  && apk add gnuplot \
    --update-cache \
    --repository http://dl-3.alpinelinux.org/alpine/edge/testing/

ENV TSDB_VERSION 2.2.0
ENV HBASE_VERSION 1.1.3
ENV JAVA_HOME /usr/lib/jvm/java-1.7-openjdk
ENV PATH $PATH:/usr/lib/jvm/java-1.7-openjdk/bin/

RUN mkdir -p /opt/bin/

RUN mkdir /opt/opentsdb/
WORKDIR /opt/opentsdb/
RUN apk --update add --virtual builddeps \
    build-base \
    autoconf \
    automake \
    git \
    python \
  && : Install OpenTSDB and scripts \
  && wget --no-check-certificate \
    -O v${TSDB_VERSION}.zip \
    https://github.com/OpenTSDB/opentsdb/archive/v${TSDB_VERSION}.zip \
  && unzip v${TSDB_VERSION}.zip \
  && rm v${TSDB_VERSION}.zip \
  && cd /opt/opentsdb/opentsdb-${TSDB_VERSION} \
  && ./build.sh \
  && : because of issue https://github.com/OpenTSDB/opentsdb/issues/707 \
  && : commented lines do not work. These can be uncommeted when version of \
  && : tsdb is bumped. Entrypoint will have to be updated too. \
  && : cd build \
  && : make install \
  && : cd / \
  && : rm -rf /opt/opentsdb/opentsdb-${TSDB_VERSION} \
  && apk del builddeps \
  && rm -rf /var/cache/apk/*

#Install HBase and scripts
RUN mkdir -p /data/hbase /root/.profile.d /opt/downloads

WORKDIR /opt/downloads
RUN wget -O hbase-${HBASE_VERSION}.bin.tar.gz http://archive.apache.org/dist/hbase/1.1.3/hbase-1.1.3-bin.tar.gz && \
    tar xzvf hbase-${HBASE_VERSION}.bin.tar.gz && \
    mv hbase-${HBASE_VERSION} /opt/hbase && \
    rm hbase-${HBASE_VERSION}.bin.tar.gz

ADD docker/hbase-site.xml /opt/hbase/conf/
ADD docker/start_opentsdb.sh /opt/bin/
ADD docker/create_tsdb_tables.sh /opt/bin/
ADD docker/start_hbase.sh /opt/bin/

# add additional config
RUN mkdir /opt/opentsdb/config
ADD opentsdb.conf

RUN for i in /opt/bin/start_hbase.sh /opt/bin/start_opentsdb.sh /opt/bin/create_tsdb_tables.sh; \
    do \
        sed -i "s#::JAVA_HOME::#$JAVA_HOME#g; s#::PATH::#$PATH#g; s#::TSDB_VERSION::#$TSDB_VERSION#g;" $i; \
    done


RUN mkdir -p /etc/services.d/hbase /etc/services.d/tsdb
RUN ln -s /opt/bin/start_hbase.sh /etc/services.d/hbase/run
RUN ln -s /opt/bin/start_opentsdb.sh /etc/services.d/tsdb/run

EXPOSE 60000 60010 60030 4242 16010

VOLUME ["/data/hbase", "/tmp"]
