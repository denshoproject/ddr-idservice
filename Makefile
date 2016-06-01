SHELL = /bin/bash

PROJECT=idservice
APP=idservice
USER=ddr

PACKAGE_SERVER=ddr.densho.org/static/$(APP)

INSTALL_BASE=/usr/local/src
INSTALLDIR=$(INSTALL_BASE)/ddr-idservice
INSTALLDIR_CMDLN=$(INSTALL_BASE)/ddr-cmdln
DOWNLOADS_DIR=/tmp/$(APP)-install
PIP_CACHE_DIR=$(INSTALL_BASE)/pip-cache
VIRTUALENV=$(INSTALL_BASE)/env/$(APP)

CONF_BASE=/etc/ddr
CONF_PRODUCTION=$(CONF_BASE)/$(PROJECT).cfg
CONF_LOCAL=$(CONF_BASE)/$(PROJECT)-local.cfg
CONF_SECRET=$(CONF_BASE)/$(PROJECT)-secret-key.txt

LOGS_BASE=/var/log/ddr
SQLITE_BASE=/var/lib/$(PROJECT)

MEDIA_BASE=/var/www/$(APP)
MEDIA_ROOT=$(MEDIA_BASE)/media
STATIC_ROOT=$(MEDIA_BASE)/static

DJANGO_CONF=$(INSTALLDIR)/idservice/idservice/settings.py
NGINX_APP_CONF=/etc/nginx/sites-available/$(APP).conf
NGINX_APP_CONF_LINK=/etc/nginx/sites-enabled/$(APP).conf
GUNICORN_CONF=/etc/supervisor/conf.d/gunicorn_$(APP).conf

MODERNIZR=modernizr-2.6.2.js
JQUERY=jquery-1.11.0.min.js
BOOTSTRAP=bootstrap-3.1.1-dist
ASSETS=ddr-idservice-assets.tar.gz
# wget https://github.com/twbs/bootstrap/releases/download/v3.1.1/bootstrap-3.1.1-dist.zip
# wget http://code.jquery.com/jquery-1.11.0.min.js

.PHONY: help


help:
	@echo "ddr-idservice Install Helper"
	@echo ""
	@echo "get     - Downloads source, installers, and assets files. Does not install."
	@echo ""
	@echo "install - Installs app, config files, and static assets.  Does not download."
	@echo "          IMPORTANT: Run 'adduser ddr' first to install ddr user and group."
	@echo "          Installation instructions: make howto-install"
	@echo ""
	@echo "syncdb  - Initialize or update Django app's database tables."
	@echo ""
	@echo "update  - Updates ddr-idservice and re-copies config files."
	@echo ""
	@echo "reload  - Reloads supervisord and nginx configs"
	@echo ""
	@echo "restart - Restarts all servers"
	@echo ""
	@echo "stop    - Stops all servers"
	@echo ""
	@echo "status  - Server status"
	@echo ""
	@echo "uninstall - Deletes 'compiled' Python files. Leaves build dirs and configs."
	@echo "clean   - Deletes files created by building the program. Leaves configs."
	@echo ""
	@echo "You can append the service name to most commands (e.g. restart-app)."
	@echo "- app"
	@echo "- redis"
	@echo "- nginx"
	@echo "- supervisord"
	@echo ""
	@echo "branch BRANCH=[branch] - Switches ddr-idservice and supporting repos to [branch]."
	@echo ""

help-all:
	@echo "install - Do a fresh install"
	@echo "install-prep    - git-config, add-user, install-misc-tools"
	@echo "install-daemons - install-nginx install-redis"
	@echo "install-app     - install-ddr-idservice"
	@echo "update  - Do an update"
	@echo "restart - Restart servers"
	@echo "status  - Server status"
	@echo "install-configs - "
	@echo "update-app - "
	@echo "uninstall - "
	@echo "clean - "

howto-install:
	@echo "HOWTO INSTALL"
	@echo "- Basic Debian netinstall"
	@echo "- # vi /etc/network/interfaces"
	@echo "- # reboot"
	@echo "- # apt-get install openssh fail2ban ufw"
	@echo "- # ufw allow 22/tcp"
	@echo "- # ufw allow 80/tcp"
	@echo "- # ufw enable"
	@echo "- # apt-get install make"
	@echo "- # adduser ddr"
	@echo "- # git clone https://github.com/densho/ddr-idservice.git $(INSTALLDIR)"
	@echo "- # cd $(INSTALLDIR)"
	@echo "- # make get"
	@echo "- # make install"
	@echo "- # make syncdb"
	@echo "- # make restart"


get: get-app

install: install-prep install-app install-configs

update: update-app

uninstall: uninstall-app

clean: clean-app


install-prep: install-core git-config install-misc-tools

install-core:
	apt-get --assume-yes install bzip2 curl gdebi-core logrotate ntp p7zip-full wget

git-config:
	git config --global alias.st status
	git config --global alias.co checkout
	git config --global alias.br branch
	git config --global alias.ci commit

install-misc-tools:
	@echo ""
	@echo "Installing miscellaneous tools -----------------------------------------"
	apt-get --assume-yes install ack-grep byobu elinks htop mg multitail


get-daemons:

install-daemons: install-nginx install-redis

install-nginx:
	@echo ""
	@echo "Nginx ------------------------------------------------------------------"
	apt-get --assume-yes install nginx

install-mariadb:
	@echo ""
	@echo "MariaDB ----------------------------------------------------------------"
	apt-get --assume-yes install mariadb-server mariadb-client libmysqlclient-dev

install-redis:
	@echo ""
	@echo "Redis ------------------------------------------------------------------"
	apt-get --assume-yes install redis-server


install-virtualenv:
	@echo ""
	@echo "install-virtualenv -----------------------------------------------------"
	apt-get --assume-yes install python-pip python-virtualenv
	test -d $(VIRTUALENV) || virtualenv --distribute --setuptools $(VIRTUALENV)

install-setuptools: install-virtualenv
	@echo ""
	@echo "install-setuptools -----------------------------------------------------"
	apt-get --assume-yes install python-dev
	source $(VIRTUALENV)/bin/activate; \
	pip install -U --download-cache=$(PIP_CACHE_DIR) bpython setuptools


get-app: get-ddr-cmdln get-ddr-idservice

install-app: install-git-annex install-virtualenv install-setuptools install-ddr-cmdln install-ddr-idservice install-configs install-daemons-configs make-static-dirs

update-app: update-ddr-cmdln update-ddr-idservice install-configs

uninstall-app: uninstall-ddr-idservice uninstall-ddr-cmdln

clean-app: clean-ddr-idservice clean-ddr-cmdln


get-ddr-cmdln:
	@echo ""
	@echo "get-ddr-cmdln --------------------------------------------------------------"
	if test -d $(INSTALL_BASE)/ddr-cmdln; \
	then cd $(INSTALLDIR_CMDLN) && git pull; \
	else cd $(INSTALL_BASE) && git clone https://github.com/densho/ddr-cmdln.git; \
	fi

install-git-annex:
ifeq "$(DEBIAN_CODENAME)" "wheezy"
	apt-get --assume-yes -t wheezy-backports install git-core git-annex
endif
ifeq "($(DEBIAN_CODENAME)" "jessie"
	apt-get --assume-yes install git-core git-annex
endif

install-ddr-cmdln:
	@echo ""
	@echo "install-ddr-cmdln ----------------------------------------------------------"
	apt-get --assume-yes install libxml2-dev libxslt1-dev libz-dev
	source $(VIRTUALENV)/bin/activate; \
	cd $(INSTALLDIR_CMDLN)/ddr && python setup.py install
	source $(VIRTUALENV)/bin/activate; \
	cd $(INSTALLDIR_CMDLN)/ddr && pip install -U --download-cache=$(PIP_CACHE_DIR) -r $(INSTALLDIR_CMDLN)/ddr/requirements/production.txt

update-ddr-cmdln:
	@echo ""
	@echo "update-ddr-cmdln -----------------------------------------------------------"
	cd $(INSTALLDIR_CMDLN) && git fetch && git pull
	source $(VIRTUALENV)/bin/activate; \
	cd $(INSTALLDIR_CMDLN)/ddr && python setup.py install
	source $(VIRTUALENV)/bin/activate; \
	cd $(INSTALLDIR_CMDLN)/ddr && pip install -U --download-cache=$(PIP_CACHE_DIR) -r $(INSTALL_BASE)/ddr-cmdln/ddr/requirements/production.txt

uninstall-ddr-cmdln:
	@echo ""
	@echo "uninstall-ddr-cmdln --------------------------------------------------------"
	source $(VIRTUALENV)/bin/activate; \
	cd $(INSTALLDIR_CMDLN)/ddr && pip uninstall -y -r $(INSTALL_BASE)/ddr-cmdln/ddr/requirements/production.txt
	-rm /usr/local/bin/ddr*
	-rm -Rf /usr/local/lib/python2.7/dist-packages/DDR*
	-rm -Rf /usr/local/lib/python2.7/dist-packages/ddr*

clean-ddr-cmdln:
	-rm -Rf $(INSTALLDIR_CMDLN)/ddr/build


get-ddr-idservice:
	@echo ""
	@echo "get-ddr-idservice ----------------------------------------------------------"
	git pull

install-ddr-idservice: install-virtualenv
	@echo ""
	@echo "install-ddr-idservice ------------------------------------------------------"
	apt-get --assume-yes install sqlite3 supervisor
	source $(VIRTUALENV)/bin/activate; \
	cd $(INSTALLDIR) && pip install -U --download-cache=$(PIP_CACHE_DIR) -r $(INSTALLDIR)/requirements/production.txt
# logs dir
	-mkdir $(LOGS_BASE)
	chown -R $(USER).root $(LOGS_BASE)
	chmod -R 755 $(LOGS_BASE)
# sqlite db dir
	-mkdir $(SQLITE_BASE)
	chown -R $(USER).root $(SQLITE_BASE)
	chmod -R 755 $(SQLITE_BASE)

update-ddr-idservice: make-static-dirs
	@echo ""
	@echo "update-ddr-idservice -------------------------------------------------------"
	git fetch && git pull
	source $(VIRTUALENV)/bin/activate; \
	pip install -U --no-download --download-cache=$(PIP_CACHE_DIR) -r $(INSTALLDIR)/requirements/production.txt

uninstall-ddr-idservice:
	@echo ""
	@echo "uninstall-ddr-idservice ----------------------------------------------------"
	cd $(INSTALLDIR)/idservice
	source $(VIRTUALENV)/bin/activate; \
	-pip uninstall -r $(INSTALLDIR)/requirements/production.txt
	-rm /usr/local/lib/python2.7/dist-packages/idservice-*
	-rm -Rf /usr/local/lib/python2.7/dist-packages/idservice

syncdb:
	source $(VIRTUALENV)/bin/activate; \
	cd $(INSTALLDIR)/idservice && python manage.py migrate --noinput
# running syncdb as root changes ownership; change back to ddr
	chown -R $(USER).root $(SQLITE_BASE)
	chmod -R 750 $(SQLITE_BASE)
	chown -R $(USER).root $(LOGS_BASE)
	chmod -R 755 $(LOGS_BASE)

restart-idservice:
	/etc/init.d/supervisor restart $(APP)

stop-idservice:
	/etc/init.d/supervisor stop $(APP)

clean-ddr-idservice:
	-rm -Rf $(INSTALLDIR)/idservice/src

clean-pip:
	-rm -Rf $(PIP_CACHE_DIR)/*


branch:
	cd $(INSTALLDIR)/idservice; python ./bin/git-checkout-branch.py $(BRANCH)


make-static-dirs:
	-mkdir $(MEDIA_BASE)
	-mkdir $(STATIC_ROOT)
	-mkdir $(STATIC_ROOT)/js
	chown -R $(USER).root $(MEDIA_BASE)
	chmod -R 755 $(MEDIA_BASE)
# static
	source $(VIRTUALENV)/bin/activate; \
	cd $(INSTALLDIR)/idservice && python manage.py collectstatic --noinput
# running collectstatic as root changes ownership; change back to ddr
	chown -R ddr.root $(LOGS_BASE)
	chmod -R 755 $(LOGS_BASE)


install-configs:
	@echo ""
	@echo "installing configs --------------------------------------------------"
	-mkdir $(CONF_BASE)
# app settings
	cp $(INSTALLDIR)/conf/idservice.cfg $(CONF_PRODUCTION)
	touch $(CONF_LOCAL)
	python -c 'import random; print "".join([random.choice("abcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*(-_=+)") for i in range(50)])' > $(CONF_SECRET)
	chown root.root $(CONF_PRODUCTION)
	chown root.ddr $(CONF_LOCAL)
	chown ddr.ddr $(CONF_SECRET)
	chmod 644 $(CONF_PRODUCTION)
	chmod 640 $(CONF_LOCAL)
	chmod 640 $(CONF_SECRET)
# django settings
	cp $(INSTALLDIR)/conf/settings.py $(DJANGO_CONF)
	chown root.root $(DJANGO_CONF)
	chmod 644 $(DJANGO_CONF)

uninstall-configs:
	-rm $(CONF_PRODUCTION)
	-rm $(CONF_LOCAL)
	-rm $(CONF_SECRET)
	-rm $(DJANGO_CONF)

install-daemons-configs:
	@echo ""
	@echo "daemon configs ------------------------------------------------------"
## nginx settings
# 	cp $(INSTALLDIR)/conf/nginx-app.conf $(NGINX_APP_CONF)
# 	chown root.root $(NGINX_APP_CONF)
# 	chmod 644 $(NGINX_APP_CONF)
# 	-ln -s $(NGINX_APP_CONF) $(NGINX_APP_CONF_LINK)
# 	-rm /etc/nginx/sites-enabled/default
# supervisord
	cp $(INSTALLDIR)/conf/gunicorn.conf $(GUNICORN_CONF)
	chown root.root $(GUNICORN_CONF)
	chmod 644 $(GUNICORN_CONF)

uninstall-daemons-configs:
	-rm $(NGINX_APP_CONF)
	-rm $(NGINX_APP_CONF_LINK)
	-rm $(GUNICORN_CONF)


reload: reload-nginx reload-supervisor

reload-nginx:
	/etc/init.d/nginx reload

reload-supervisor:
	supervisorctl reload


restart: restart-redis restart-nginx restart-supervisor

restart-redis:
	/etc/init.d/redis-server restart

restart-nginx:
	/etc/init.d/nginx restart

restart-supervisor:
	/etc/init.d/supervisor restart


stop: stop-redis stop-nginx stop-supervisor

stop-redis:
	/etc/init.d/redis-server stop

stop-nginx:
	/etc/init.d/nginx stop

stop-supervisor:
	/etc/init.d/supervisor stop all


status:
	-/etc/init.d/redis-server status
	-/etc/init.d/nginx status
	-supervisorctl status

git-status:
	@echo "------------------------------------------------------------------------"
	cd $(INSTALLDIR) && git status
