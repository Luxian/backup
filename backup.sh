#!/bin/sh

# @file:
#  Automatic backup of database and files (code + upload)
#  for WordPress
#
# This needs to be run in the webroot


# Any command which fail will cause the shell script to exit immediately
set -e

# BACKUP_DIR should be specified before running this command
if [ -z $BACKUP_DIR ]
  then
    echo 'BACKUP_DIR variable is not set' 1>&2;
    echo 'You can set this by running the command like this:' 1>&2
    echo "  BACKUP_DIR=/tmp $0" 1>&2;
    exit 1;
fi;

# 'php' is needed to extract database connection info
if ! which php 1>/dev/null
  then
    echo 'Error: php (php-cli) is not available' 1>&2
    exit 1;
fi;

# tar is needed to archive
if ! which tar 1>/dev/null
  then
    echo 'Error: tar utility is not available' 1>&2
    exit 1;
fi;

# gzip is needed to compress the archive
if ! which gzip 1>/dev/null
  then
    echo 'Error: gzip utility is not available' 1>&2;
    exit 1;
fi;

# mysqldump is needed to export the database
if ! which mysqldump 1>/dev/null
  then
    echo 'Error: mysqldump is not available';
    exit 1;
fi;

# Check if configuration file is present
if [ ! -f 'wp-config.php' ]
  then
    echo 'Error: could not find the wp-config.php file' 1>&2;
    exit 1;
fi;

# Check if configuration file contains php closing tags
# PHP closing tags don't work with current method of
# extracting database credentials and are not recommended
if cat 'wp-config.php' | grep -q '?>'
  then
    echo 'Error: wp-config.php contains PHP closing tags ?>. Please remove them' 1>&2;
    exit 1;
fi;

# Variables
SITENAME="lopan.ch";
NOW=$(date +"%Y-%m-%d-%H%M");
FILE="$SITENAME.$NOW.tar";
WWW_DIR=$(pwd);

# Extract database connection details from wp-config.php
WPDB_USER=$(echo "`cat wp-config.php`; echo DB_USER;" | php -d error_reporting=0);
WPDB_PASS=$(echo "`cat wp-config.php`; echo DB_PASSWORD;" | php -d error_reporting=0);
WPDB_NAME=$(echo "`cat wp-config.php`; echo DB_NAME;" | php -d error_reporting=0);
WPDB_HOST=$(echo "`cat wp-config.php`; echo DB_HOST;" | php -d error_reporting=0);
WPDB_FILE="$SITENAME.$NOW.sql"

# Archive all the www folder
#   -C $WWW_DIR:
#   -s '/./www/gs': rename '.' with www inside the archive
#   --format=ustar: prevent tar from creatign PaxHeader folder inside archives
tar \
  -C $WWW_DIR \
  -s '/./www/' \
  --format=ustar \
  --exclude=.git \
  --exclude=.svn \
  --exclude=cgi-bin \
  -cf $BACKUP_DIR/$FILE .

# Create a directory for the SQL dump
mkdir -p "$BACKUP_DIR/sql";
# Call mysqldump and ignore errors
# For example: 'Warning: Using a password on the command line ...
mysqldump --user="$WPDB_USER" --password="$WPDB_PASS" --host="$WPDB_HOST" $DB_NAME > "$BACKUP_DIR/sql/$WPDB_FILE" 2>/dev/null

# Add SQL dump to the archive
tar \
  --format=ustar \
  -C $BACKUP_DIR \
  -rf $BACKUP_DIR/$FILE sql/

# Remove the sql file and folder since it's added to archive
rm -rf "$BACKUP_DIR/sql"

# Compress the archive
# --best: best compressiong level
# --force: in case backup file already exists, overwrite it
gzip --best --force $BACKUP_DIR/$FILE;

# Print the backup file name
if [ -f "$BACKUP_DIR/$FILE.gz" ]
  then
    echo "$BACKUP_DIR/$FILE.gz";
  elif [ -f $BACKUP_DIR/$FILE ]
    then
      echo $BACKUP_DIR/$FILE;
  else
    echo "Backup file it's missing: $BACKUP_DIR/$FILE[.gz]" 1>&2;
    exit 1;
fi

exit 0;
