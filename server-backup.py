#!/usr/bin/env python

import datetime
import os
import shutil
import subprocess

# server-backup.py
# Murtaza Gulamali (01/01/2012)
#
# A simple script to backup directories (recursively) and MySQL databases
# on a Linux server. Useful for backing up a Wordpress install.
#
# This software is released under the terms and conditions of The MIT License:
# http://www.opensource.org/licenses/mit-license.php

# directory (as a string) or directories (as a list of strings) to backup
DIRS = ['DIRECTORY_1',
        'DIRECTORY_2',
        'DIRECTORY_3']

# database (as a string) or databases (as a list of strings) to backup
DBS = ['DB_1',
       'DB_2',
       'DB_3']

# database server login details
DB_USER = 'MYSQL_USERNAME'
DB_PSWD = 'MYSQL_PASSWORD'

# temporary directory in which to create backup
TMP_DIR = '/tmp'

# prefix for backup filenames
FILE_PREFIX = 'backup'

# -------------------- NO NEED TO EDIT ANYTHING BELOW HERE --------------------

def archive(file_or_dir, backup_file, log_file):
    """Archive specified file or directory to specified backup file."""
    backup_file_stem, backup_file_ext = os.path.splitext(os.path.basename(backup_file))
    # NB: could use shutil.make_archive() but this doesn't utilise the transform feature
    command = ['tar','-uf',backup_file,'--transform','\'s,^,{0:s},S\''.format(backup_file_stem),file_or_dir]
    subprocess.call(command,stdout=log_file,stderr=log_file)
    
def archive_db(db, backup_file, log_file):
    """Archive specified database to specified backup file."""
    sql_file = os.path.join(TMP_DIR,'{0:s}.sql'.format(db))
    # NB: works for InnoDB type tables, for MyISAM type tables use '-l' instead of '--single-transaction'
    command = ['mysqldump','--add-drop-database','--single-transaction','-u{0:s}'.format(DB_USER),'-p{0:s}'.format(DB_PSWD),db,'-r{0:s}'.format(sql_file)]
    subprocess.call(command,stdout=log_file,stderr=log_file)
    archive(sql_file,backup_file,log_file)
    os.remove(sql_file)

def compress(backup_file, log_file):
    """Compress specified backup file."""
    command = ['gzip','-q','--best',backup_file]
    subprocess.call(command,stdout=log_file,stderr=log_file)

if (__name__=='__main__'):
    # get the date and time now
    now = datetime.datetime.now().strftime('%Y-%m-%d-%H%M')
    
    # create filename for backup
    backup_file = os.path.join(TMP_DIR,'{0:s}-{1:s}.tar'.format(FILE_PREFIX,now))

    # create file for log file
    log_file = file(os.path.join(TMP_DIR,'{0:s}-{1:s}.log'.format(FILE_PREFIX,now)),'w')

    # backup directories
    if type(DIRS)==type([]):
        for d in DIRS:
            archive(d, backup_file, log_file)
    elif type(DIRS)==type(''):
        archive(DIRS, backup_file, log_file)
    
    # backup databases
    if type(DBS)==type([]):
        for db in DBS:
            archive_db(db, backup_file, log_file)
    elif type(DBS)==type(""):
        archive_db(DBS, backup_file, log_file)

    # compress archive
    compress(backup_file, log_file)

    # move files to current directory
    shutil.move(backup_file,os.getcwd())
    shutil.move(log_file,os.getcwd())
