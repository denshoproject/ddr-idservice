================
Installing ddr-idservice
================

This page documents the process of installing and configuring `ddr-idservice` on an existing Debian Linux machine.

Most of the commands you will type will be entered as `root`.  To become `root`, type the following at a command prompt::

    $ su - root
    [enter root password]

As per convention, variables in this documentation are written in upper case with underscores, starting with a "$" sign.



DDR Applications and Dependencies - Automated Installation
==========================================================

In this section we will use a script to automatically install the DDR code and its supporting applications.

Log in to your VM and become `root`.  Then add a `ddr` user, install the prerequisites, and install the `ddr-idservice` app itself.::

    # adduser ddr
    [enter info]
    # apt-get install git-core
    
    # git clone git@github.com:densho/ddr-idservice.git /opt/ddr-idservice
    # cd /opt/ddr-idservice/idservice

    # If you are testing a branch, switch to that branch.
    # git checkout -b BRANCHNAME origin/BRANCHNAME

    # make install-mariadb
    # mysql -p -u root
    CREATE DATABASE ddridservice CHARACTER SET utf8;
    GRANT ALL PRIVILEGES ON ddridservice.* TO ddr@localhost IDENTIFIED BY 'password';
    FLUSH PRIVILEGES;
    
    # make get
    # make install

Wait as Make installs Debian packages and Python code and builds up your system.  On a basic VM this takes between 5-10 minutes.



Configuration
=============

The default settings in `/etc/ddr/idservice.cfg` are specific to the Densho production system.  Settings in `/etc/ddr/idservice-local.cfg` will override the defaults.

Edit `/etc/ddr/idservice-local.cfg` to include the following text.::

    [public]
    
    # Absolute path to directory that will hold static and user-uploaded files.
    # Note: Should match MEDIA_ROOT and STATIC_ROOT in Makefile.
    # Note: Should not have trailing slashes.
    static_root=/var/www/idservice/static
    media_root=/var/www/idservice/media

To get the nice Django error messages edit `/opt/ddr-idservice/idservice/settings.py`.  **WARNING: setting `DEBUG = True` in a production environment is a security risk!**::

    DEBUG = True
    THUMBNAIL_DEBUG = False

`ddr-idservice` uses the Django ORM to store data about locally-created thumbnail images in a SQLite3 database.  Create database tables for installed applications.::

    # cd /opt/ddr-idservice/idservice
    # su ddr
    $ python manage.py migrate
    $ python manage.py createsuperuser

Restart the servers and the web application to see the effects of your edits.::

    # make restart

At this point `ddr-idservice` is installed but the Elasticsearch database contains no data.
