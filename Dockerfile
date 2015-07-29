#Basic update/upgrade/setup and install packages needed in other sections at once to save on number of apt-get instantiations
FROM ubuntu
RUN if [ ! $(grep universe /etc/apt/sources.list) ]; then sed 's/main$/main universe/' -i /etc/apt/sources.list && apt-get update; fi
RUN apt-get -y update && apt-get -y upgrade && \
    apt-get install -y automake \
                       build-essential \
                       curl \
                       git-core \
                       gnuplot \
                       openjdk-6-jdk \
                       openssh-server \
                       python \
                       python-dev \
                       supervisor \
                       unzip

#Install HBase and scripts
RUN mkdir -p /root/.profile.d

# by merging this into one step, the FS layer is going to be smalling. 
# Moreover since ADD will download the file first and check the complete step will be cached if it was done 
RUN curl -Ls -o /tmp/hbase-0.94.27.tar.gz http://apache.org/dist/hbase/hbase-0.94.27/hbase-0.94.27.tar.gz && \
   tar xzf /tmp/hbase-*gz && rm /tmp/hbase-*gz && \
   mv hbase-* /opt/hbase
ADD start_hbase.sh /opt/sei-bin/
ADD hbase-site.xml /opt/hbase/conf/
EXPOSE 60000 60010 60030

#Install OpenTSDB and scripts
RUN git clone -b next --single-branch git://github.com/OpenTSDB/opentsdb.git /opt/opentsdb && \
    cd /opt/opentsdb && bash ./build.sh
ADD start_opentsdb.sh create_tsdb_tables.sh /opt/sei-bin/
EXPOSE 4242

#Install Supervisord
RUN mkdir -p /var/log/supervisor
ADD supervisor/*e.conf /etc/supervisor/conf.d/

#Configure SSHD properly
RUN mkdir -p /root/.ssh && chmod 0600 /root/.ssh && \
    sed -ri 's/UsePAM yes/#UsePAM yes/g; s/#UsePAM no/UsePAM no/g;' /etc/ssh/sshd_config && \
    mkdir -p /var/run/sshd && \
    chown 0:0 /var/run/sshd && \
    chmod 0744 /var/run/sshd
ADD create_ssh_key.sh /opt/sei-bin/

#Install serf and scripts
RUN curl -Ls -o /tmp/0.6.1_linux_amd64.zip https://dl.bintray.com/mitchellh/serf/0.6.1_linux_amd64.zip && \
    mkdir /tmp/serf_src/ && cd /tmp/serf_src/ && unzip /tmp/0.6.1_linux_amd64.zip && \
    mv /tmp/serf_src/serf /usr/bin && rm -rf /tmp/0.6.1_linux_amd64.zip /tmp/serf_src/
ADD serf-start.sh serf-join.sh /opt/sei-bin/

VOLUME ["/data/hbase"]

CMD ["/usr/bin/supervisord"]

