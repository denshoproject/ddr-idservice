SHELL = /bin/bash

PROJECT=idservice
APP=idservice
USER=ddr

PACKAGE_SERVER=ddr.densho.org/static/$(APP)

INSTALL_BASE=/usr/local/src
INSTALLDIR=$(INSTALL_BASE)/ddr-idservice
DOWNLOADS_DIR=/tmp/$(APP)-install
PIP_CACHE_DIR=$(INSTALL_BASE)/pip-cache
VIRTUALENV=$(INSTALL_BASE)/env/$(APP)

CONF_BASE=/etc/ddr
CONF_PRODUCTION=$(CONF_BASE)/$(PROJECT).cfg
CONF_LOCAL=$(CONF_BASE)/$(PROJECT)-local.cfg
CONF_SECRET=$(CONF_BASE)/$(PROJECT)-secret-key.txt

LOGS_BASE=/var/log/$(PROJECT)
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
	@echo "install-static  - "
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
	@echo "- # cd $(INSTALLDIR)/idservice"
	@echo "- # make install"
	@echo "- # make syncdb"
	@echo "- # make restart"


get: get-app get-static

install: install-prep install-app install-static install-configs

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


get-app: get-ddr-idservice get-static

install-app: install-ddr-idservice

update-app: update-ddr-idservice install-configs

uninstall-app: uninstall-ddr-idservice

clean-app: clean-ddr-idservice


get-ddr-idservice:
	git pull
	pip install --download=$(PIP_CACHE_DIR) --exists-action=i -r $(INSTALLDIR)/requirements/production.txt

install-ddr-idservice: install-virtualenv
	@echo ""
	@echo "ddr-idservice --------------------------------------------------------------"
	apt-get --assume-yes install sqlite3 supervisor
	source $(VIRTUALENV)/bin/activate; \
	pip install -U --no-index --find-links=$(PIP_CACHE_DIR) -r $(INSTALLDIR)/requirements/production.txt
# logs dir
	-mkdir $(LOGS_BASE)
	chown -R $(USER).root $(LOGS_BASE)
	chmod -R 755 $(LOGS_BASE)
# sqlite db dir
	-mkdir $(SQLITE_BASE)
	chown -R $(USER).root $(SQLITE_BASE)
	chmod -R 755 $(SQLITE_BASE)

syncdb:
	source $(VIRTUALENV)/bin/activate; \
	cd $(INSTALLDIR)/idservice && python manage.py migrate --noinput
	chown -R $(USER).root $(SQLITE_BASE)
	chmod -R 750 $(SQLITE_BASE)
	chown -R $(USER).root $(LOGS_BASE)
	chmod -R 755 $(LOGS_BASE)

update-ddr-idservice:
	@echo ""
	@echo "ddr-idservice --------------------------------------------------------------"
	git fetch && git pull
	source $(VIRTUALENV)/bin/activate; \
	pip install -U --no-download --download-cache=$(PIP_CACHE_DIR) -r $(INSTALLDIR)/requirements/production.txt

uninstall-ddr-idservice:
	cd $(INSTALLDIR)/idservice
	source $(VIRTUALENV)/bin/activate; \
	-pip uninstall -r $(INSTALLDIR)/requirements/production.txt
	-rm /usr/local/lib/python2.7/dist-packages/idservice-*
	-rm -Rf /usr/local/lib/python2.7/dist-packages/idservice

restart-idservice:
	/etc/init.d/supervisor restart idservice

stop-idservice:
	/etc/init.d/supervisor stop idservice

clean-ddr-idservice:
	-rm -Rf $(INSTALLDIR)/idservice/src

clean-pip:
	-rm -Rf $(PIP_CACHE_DIR)/*


branch:
	cd $(INSTALLDIR)/idservice; python ./bin/git-checkout-branch.py $(BRANCH)


get-static: get-app-assets get-modernizr get-bootstrap get-jquery

install-static: install-app-assets install-modernizr install-bootstrap install-jquery

clean-static: clean-modernizr clean-bootstrap clean-jquery


make-static-dirs:
	-mkdir $(MEDIA_BASE)
	-mkdir $(STATIC_ROOT)
	-mkdir $(STATIC_ROOT)/js
	chown -R $(USER).root $(MEDIA_BASE)
	chmod -R 755 $(MEDIA_BASE)

get-app-assets:
	-wget -nc -P $(DOWNLOADS_DIR) http://$(PACKAGE_SERVER)/$(ASSETS)

install-app-assets: make-static-dirs
	@echo ""
	@echo "get assets --------------------------------------------------------------"
	-tar xzvf $(DOWNLOADS_DIR)/$(APP)-assets.tar.gz -C $(STATIC_ROOT)/


get-modernizr:
	-wget -nc -P $(DOWNLOADS_DIR) http://$(PACKAGE_SERVER)/$(MODERNIZR)

install-modernizr: make-static-dirs
	@echo ""
	@echo "Modernizr --------------------------------------------------------------"
	-cp -R $(DOWNLOADS_DIR)/$(MODERNIZR) $(STATIC_ROOT)/js/

clean-modernizr:
	-rm $(STATIC_ROOT)/js/$(MODERNIZR)*


get-bootstrap:
	-wget -nc -P $(DOWNLOADS_DIR) http://$(PACKAGE_SERVER)/$(BOOTSTRAP).zip

install-bootstrap: make-static-dirs
	@echo ""
	@echo "Bootstrap --------------------------------------------------------------"
	-7z x -y -o$(STATIC_ROOT) $(DOWNLOADS_DIR)/$(BOOTSTRAP).zip
	-ln -s $(STATIC_ROOT)/$(BOOTSTRAP) $(STATIC_ROOT)/bootstrap

clean-bootstrap:
	-rm -Rf $(STATIC_ROOT)/$(BOOTSTRAP)


get-jquery:
	-wget -nc -P $(DOWNLOADS_DIR) http://$(PACKAGE_SERVER)/$(JQUERY)

install-jquery: make-static-dirs
	@echo ""
	@echo "jQuery -----------------------------------------------------------------"
#	wget -nc -P $(STATIC_ROOT)/js http://$(PACKAGE_SERVER)/$(JQUERY)
#	-ln -s $(STATIC_ROOT)/js/$(JQUERY) $(STATIC_ROOT)/js/jquery.js
	-cp -R $(DOWNLOADS_DIR)/$(JQUERY) $(STATIC_ROOT)/js/
	-ln -s $(STATIC_ROOT)/js/$(JQUERY) $(STATIC_ROOT)/js/jquery.js

clean-jquery:
	-rm -Rf $(STATIC_ROOT)/js/$(JQUERY)
	-rm $(STATIC_ROOT)/js/jquery.js


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
# nginx settings
	cp $(INSTALLDIR)/conf/nginx-app.conf $(NGINX_APP_CONF)
	chown root.root $(NGINX_APP_CONF)
	chmod 644 $(NGINX_APP_CONF)
	-ln -s $(NGINX_APP_CONF) $(NGINX_APP_CONF_LINK)
	-rm /etc/nginx/sites-enabled/default
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
	/etc/init.d/supervisor stop


status:
	-/etc/init.d/redis-server status
	-/etc/init.d/nginx status
	-supervisorctl status

git-status:
	@echo "------------------------------------------------------------------------"
	cd $(INSTALLDIR) && git status
