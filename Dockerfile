FROM alpine:latest

ENV TINI_VERSION v0.18.0
ENV TSDB_VERSION 2.4.0
ENV HBASE_VERSION 1.4.4
ENV GNUPLOT_VERSION 5.2.4
ENV JAVA_HOME /usr/lib/jvm/java-1.8-openjdk
ENV PATH $PATH:/usr/lib/jvm/java-1.8-openjdk/bin/
ENV ALPINE_PACKAGES "rsyslog bash openjdk8 make wget libgd libpng libjpeg libwebp libjpeg-turbo cairo pango lua"
ENV BUILD_PACKAGES "build-base autoconf automake git python3-dev cairo-dev pango-dev gd-dev lua-dev readline-dev libpng-dev libjpeg-turbo-dev libwebp-dev sed"
ENV HBASE_OPTS "-XX:+UseConcMarkSweepGC -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap"
ENV JVMARGS "-XX:+UseConcMarkSweepGC -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap -enableassertions -enablesystemassertions"

# Tini is a tiny init that helps when a container is being culled to stop things nicely
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-static-amd64 /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

# Add the base packages we'll need
RUN apk --update add apk-tools \
    && apk add ${ALPINE_PACKAGES} \
      # repo required for gnuplot \
      --repository http://dl-cdn.alpinelinux.org/alpine/v3.0/testing/ \
    && mkdir -p /opt/opentsdb

WORKDIR /opt/opentsdb/

# Add build deps, build opentsdb, and clean up afterwards.
RUN set -ex && apk add --virtual builddeps ${BUILD_PACKAGES}

RUN ln -s /usr/bin/python3 /usr/bin/python

RUN wget --no-check-certificate \
    -O v${TSDB_VERSION}.zip \
    https://github.com/OpenTSDB/opentsdb/archive/v${TSDB_VERSION}.zip \
  && unzip v${TSDB_VERSION}.zip \
  && rm v${TSDB_VERSION}.zip \
  && cd /opt/opentsdb/opentsdb-${TSDB_VERSION} \
  && echo "tsd.http.request.enable_chunked = true" >> src/opentsdb.conf \
  && echo "tsd.http.request.max_chunk = 1000000" >> src/opentsdb.conf 

RUN cd /opt/opentsdb/opentsdb-${TSDB_VERSION} \
  && find . | xargs grep -s central.maven.org | cut -f1 -d : | xargs sed -i "s/http:\/\/central/https:\/\/repo1/g" \
  && find . | xargs grep -s repo1.maven.org | cut -f1 -d : | xargs sed -i "s/http:\/\/repo1/https:\/\/repo1/g" \
  && ./build.sh \
  && cp build-aux/install-sh build/build-aux \
  && cd build \
  && make install \
  && cd / \
  && rm -rf /opt/opentsdb/opentsdb-${TSDB_VERSION}

RUN cd /tmp && \
    wget https://sourceforge.net/projects/gnuplot/files/gnuplot/${GNUPLOT_VERSION}/gnuplot-${GNUPLOT_VERSION}.tar.gz && \
    tar xzf gnuplot-${GNUPLOT_VERSION}.tar.gz && \
    cd gnuplot-${GNUPLOT_VERSION} && \
    ./configure && \
    make install && \
    cd /tmp && rm -rf /tmp/gnuplot-${GNUPLOT_VERSION} && rm /tmp/gnuplot-${GNUPLOT_VERSION}.tar.gz

RUN apk del builddeps && rm -rf /var/cache/apk/*

#Install HBase and scripts
RUN mkdir -p /data/hbase /root/.profile.d /opt/downloads
WORKDIR /opt/downloads
RUN wget -O hbase-${HBASE_VERSION}.bin.tar.gz http://archive.apache.org/dist/hbase/${HBASE_VERSION}/hbase-${HBASE_VERSION}-bin.tar.gz \
    && tar xzvf hbase-${HBASE_VERSION}.bin.tar.gz \
    && mv hbase-${HBASE_VERSION} /opt/hbase \
    && rm -r /opt/hbase/docs \
    && rm hbase-${HBASE_VERSION}.bin.tar.gz

# Add misc startup files
RUN ln -s /usr/local/share/opentsdb/etc/opentsdb /etc/opentsdb \
    && rm /etc/opentsdb/opentsdb.conf \
    && mkdir /opentsdb-plugins
ADD files/opentsdb.conf /etc/opentsdb/opentsdb.conf.sample
ADD files/hbase-site.xml /opt/hbase/conf/hbase-site.xml.sample
ADD files/start_opentsdb.sh /opt/bin/
ADD files/create_tsdb_tables.sh /opt/bin/
ADD files/start_hbase.sh /opt/bin/
ADD files/entrypoint.sh /entrypoint.sh

# Fix ENV variables in installed scripts
RUN for i in /opt/bin/start_hbase.sh /opt/bin/start_opentsdb.sh /opt/bin/create_tsdb_tables.sh; \
    do \
        sed -i "s#::JAVA_HOME::#$JAVA_HOME#g; s#::PATH::#$PATH#g; s#::TSDB_VERSION::#$TSDB_VERSION#g;" $i; \
    done

RUN echo "export HBASE_OPTS=\"${HBASE_OPTS}\"" >> /opt/hbase/conf/hbase-env.sh


#4242 is tsdb, rest are hbase ports
EXPOSE 60000 60010 60030 4242 16010 16070


#HBase is configured to store data in /data/hbase, vol-mount it to persist your data.
VOLUME ["/data/hbase", "/tmp", "/opentsdb-plugins"]

CMD ["/entrypoint.sh"]
