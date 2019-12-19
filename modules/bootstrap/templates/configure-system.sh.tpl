#!/bin/bash

# http://tldp.org/LDP/abs/html/options.html
set -o errexit
set -o nounset


sudo -u root mkdir -p /etc/spark/conf/
aws s3 cp s3://${bootstrap_bucket}/log4j_spark.properties /tmp/
sudo -u root cp /tmp/log4j_spark.properties /etc/spark/conf/log4j.properties


sudo -u root python3 -m pip install boto3 pandas numpy simplejson mlflow koalas Click watchtower s3fs
