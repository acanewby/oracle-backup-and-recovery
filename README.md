# oracle-backup-and-recovery

_A set of utilities to support Oracle Database Backup and Restore activities_

## Background
This document describes a standard methodology for executing automated backups of Oracle databases, using both hot and cold-backup methodologies.  A restore utility script is described as well.

## Scripts
The architecture of the solution is simple:  a single driver shell script sets up the necessary environment and then invokes the appropriate .SQL script to execute either a hot or cold backup.  The driver script is constructed to run without modification as a cron job.

## Installation
Install the following scripts in `/home/oracle/bin`:

* backup-db
* execute-cold-backup.sql
* execute-hot-backup.sql
* restore-dbfile

## Driver script – backup-db
The backup-db script relies on the existence of an `/etc/oratab` entry for the database being backed up.  This provides the script with the information it needs to set the correct `ORACLE_HOME` environment.  The script also determines the appropriate backup type (“hot” or “cold”) and invokes the appropriate .SQL script for preparation and execution of the backup.

_Note:  This script is not Windows-compatible_

Usage: `backup-db.sh <hot|cold> <database>`

This will launch the backup and automatically invoke one of the two scripts below. They are described here purelky for information and are not intended to be invoked directly.

### Hot backup script – execute-hotbackup.sql
The execute-hotbackup.sql PL/SQL script uses the “run-SQL-to-generate-SQL” technique to produce a dynamic backup script.  A pair of PL/SQL cursors iterate over the `DBA_TABLESPACES` and `DBA_DATA_FILES` views to create a hotbackup script that puts every eligible tablespace in succession into backup mode and then uses gzip to copy the underlying datafiles to a backup location.  

The script also generates a log file, which records all actions taken as well as the start and stop time.

_Note that the script works equally well for both filesystems and raw devices._

### Cold backup script – execute-coldbackup.sql
The cold backup script operates identically to the hot backup script except in two respects:
It queries different dictionary views since it must back up a larger set of data files (i.e. temporary tablespace files, redo logs and control files). It automatically stops the database to perform the backup and restarts it once completed

## File restore script – restore-dbfile

The restore-dbfile script will restore a single file that was backed up with the backup procedure previously described. The restore script depends on a file name having the “[slash]” string of characters instead of the actual slashes “/” to define its file path. For example a file named `[slash]dev[slash]client_data01.gz` will be restored to `/dev/client_data01`. The restore script will substitute the “[slash]” strings with slashes “/”, and use the gunzip command to restore a file.

Usage: `restore-dbfile <filename>.gz`

The file name in the parameter <filename>.gz can be defined using an absolute or a relative path.

