#!/bin/bash

# This script installs Tomcat and Solr/Lucene for search indexing of the
# KhanAcademy.org content.

# This script assumes an Ubuntu 11.10 server.
# This git repository should be cloned into $HOME/aws-config.
export REPO_ROOT=$HOME/aws-config/production-rpc
export SCRIPT_ROOT=$REPO_ROOT/scripts
export SOLR_VERSION=3.6.0

# chdir to $REPO_ROOT
cd $REPO_ROOT

# Start out by installing package dependencies
sudo apt-get install lighttpd tomcat6 curl mailutils moreutils

# Configure Tomcat: Set port number to 9001
sudo sed -i 's/8080/9001/g' /var/lib/tomcat6/conf/server.xml

# Download and extract the Solr .war file
curl http://apache.tradebit.com/pub/lucene/solr/$SOLR_VERSION/apache-solr-$SOLR_VERSION.tgz > $REPO_ROOT/apache-solr.tgz
tar -xf $REPO_ROOT/apache-solr.tgz
cp apache-solr-$SOLR_VERSION/dist/apache-solr-$SOLR_VERSION.war $REPO_ROOT/solr/solr.war
rm -rf apache-solr-$SOLR_VERSION
rm $REPO_ROOT/apache-solr.tgz

# Copy configuration data
sudo ln -s $REPO_ROOT/config/solr_tomcat_context.xml /var/lib/tomcat6/conf/Catalina/localhost/solr.xml

# Create symlink to Solr app directory outside of $HOME
sudo ln -s $REPO_ROOT/solr /var/lib/tomcat6/khan-solr

# Set permissions so that Tomcat can read the files
sudo chown -R tomcat6:tomcat6 $REPO_ROOT/solr

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

# Create a local user crontab
cat <<EOF | crontab -
MAILTO=production-rpc-admin+search-cron@khanacademy.org
0 * * * * $SCRIPT_ROOT/cronic.bash $SCRIPT_ROOT/update_solr.bash
EOF
