#!/bin/bash

# This script is run from a cron job and in turn calls the index updating script.
# It will send out mail if there is an error running the update script.

# This script assumes an Ubuntu 11.10 server and home directory /home/ubuntu.
# This git repository should be cloned into /home/ubuntu/aws-config.
export REPO_ROOT=/home/ubuntu/aws-config/production-rpc
export SCRIPT_ROOT=$REPO_ROOT/scripts

# TODO (tom): Find the right mailing list to send this error out to
$SCRIPT_ROOT/cronic.bash $SCRIPT_ROOT/update_solr.bash | ifne mail -s "Error occurred while updating the search index on search-rpc!" tom@khanacademy.org
