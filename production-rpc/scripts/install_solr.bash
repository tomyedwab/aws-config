#!/bin/bash

# This script installs Tomcat and Solr/Lucene for search indexing of the
# KhanAcademy.org content.

# This script assumes an Ubuntu 11.10 server and home directory /home/ubuntu.
# This git repository should be cloned into /home/ubuntu/aws-config.
export REPO_ROOT=/home/ubuntu/aws-config/production-rpc
export SCRIPT_ROOT=$REPO_ROOT/scripts

# Start out by installing package dependencies
sudo apt-get install lighttpd tomcat6 curl mailutils moreutils

# Configure Tomcat: Set port number to 9001
sudo sed -i 's/8080/9001/g' /var/lib/tomcat6/conf/server.xml

# Copy configuration data
sudo ln -s $REPO_ROOT/config/solr_tomcat_context.xml /var/lib/tomcat6/conf/Catalina/localhost/solr.xml

# Set permissions so that Tomcat can read the files
sudo chown -R tomcat6:tomcat6 solr

# Delete the default Tomcat index page
sudo rm /var/lib/tomcat6/webapps/ROOT/index.html

# Restart Tomcat server to pick up our changes
sudo /etc/init.d/tomcat6 restart

# Configure lighttpd to redirect requests:
#   search-rpc.khanacademy.org => localhost:9001 (Tomcat)
sudo rm /etc/lighttpd/lighttpd.conf
sudo ln -s $REPO_ROOT/config/lighttpd.conf /etc/lighttpd/lighttpd.conf

# Restart lighttpd to pick up our changes
sudo /etc/init.d/lighttpd restart

# Initialize the search index with the latest data
$SCRIPT_ROOT/update_solr.bash

# Set up a cron job to update the index every hour
sudo ln -s $SCRIPT_ROOT/update_solr_wrapper.bash /etc/cron.hourly/update_solr
