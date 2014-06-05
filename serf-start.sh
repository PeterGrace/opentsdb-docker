#!/bin/bash
exec serf agent -tag role=hbase -tag role=opentsdb -tag role=4242
