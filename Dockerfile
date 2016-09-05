FROM janeczku/alpine-kubernetes:3.2

RUN apk --update add \
    rsyslog \
    bash \
    openjdk7 \
    make \
    curl \
  && : adding gnuplot for graphing \
  && apk add gnuplot \
    --update-cache \
    --repository http://mirror.leaseweb.com/alpine/edge/testing/

ENV TSDB_VERSION 2.3.0RC1
ENV HBASE_VERSION 1.2.1
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
  && curl -k -L -s -o - https://github.com/OpenTSDB/opentsdb/archive/v${TSDB_VERSION}.tar.gz | tar xzf - \
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
RUN mkdir -p /data/hbase /root/.profile.d
RUN curl -s -o - \
    http://archive.apache.org/dist/hbase/${HBASE_VERSION}/hbase-${HBASE_VERSION}-bin.tar.gz | tar xzf - --exclude=docs \
  && mv hbase-${HBASE_VERSION} /opt/hbase

ADD docker/hbase-site.xml /opt/hbase/conf/
ADD docker/start_opentsdb.sh /opt/bin/
ADD docker/create_tsdb_tables.sh /opt/bin/
ADD docker/start_hbase.sh /opt/bin/
ADD docker/opentsdb.conf /opt/opentsdb.conf

RUN for i in /opt/bin/start_hbase.sh /opt/bin/start_opentsdb.sh /opt/bin/create_tsdb_tables.sh; \
    do \
        sed -i "s#::JAVA_HOME::#$JAVA_HOME#g; s#::PATH::#$PATH#g; s#::TSDB_VERSION::#$TSDB_VERSION#g;" $i; \
    done

RUN mkdir -p /etc/services.d/hbase /etc/services.d/tsdb
RUN ln -s /opt/bin/start_hbase.sh /etc/services.d/hbase/run
RUN ln -s /opt/bin/start_opentsdb.sh /etc/services.d/tsdb/run

EXPOSE 60000 60010 60030 4242 16010

VOLUME ["/data/hbase", "/tmp"]
