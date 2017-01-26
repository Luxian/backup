# backup
Simple shell script that genereates a `tar.gz` file with a complete backup of a Wordpress site (code, uploads, database)

# Requirements
- php-cli: used to read the `wp-config.php` file and extract database credentials
- mysqldump: to generate database dump
- tar: used to archive everything in one file
- gzip: compress final archive
- `$BACKUP_DIR`: bash variable to specify where the backup should be put


# Usage:
```bash
cd /var/www/example.com && BACKUP_DIR=/tmp ./backup.sh
```
This will backup the WordPress installation with the web root directory `/var/www/example.com`

# Notes && todo:
- a `sql` directory will be created inside $BACKUP_DIR and remove it completely
regardless if existed before or not
- add a verbose mode to debug (even add a log into the final archive?)
