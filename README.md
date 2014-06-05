opentsdb-docker
===============

Files required to make a trusted opentsdb Docker such that opentsdb can be used for other project (e.g. scollector)

Notes
=====
 * This container has serf (www.serfdom.io) preinstalled.  It is expecting you to link the container to another container (such as ctlc/serf) with id "serf" (--link myserfcontainername:serf)
 * If you need to ssh to the container, make sure to pass your ssh key into the run command, e.g. docker run -tiP -e "SSH_KEY=$(cat /root/.ssh/id_dsa.pub)" petergrace/opentsdb
   
