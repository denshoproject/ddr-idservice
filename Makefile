PROJECT=ddridservice
APP=idservice
USER=ddr
SHELL = /bin/bash

APP_VERSION := $(shell cat VERSION)
GIT_SOURCE_URL=https://github.com/densho/ddr-idservice

# Release name e.g. jessie
DEBIAN_CODENAME := $(shell lsb_release -sc)
# Release numbers e.g. 8.10
DEBIAN_RELEASE := $(shell lsb_release -sr)
# Sortable major version tag e.g. deb8
DEBIAN_RELEASE_TAG = deb$(shell lsb_release -sr | cut -c1)

# current branch name minus dashes or underscores
PACKAGE_BRANCH := $(shell git rev-parse --abbrev-ref HEAD | tr -d _ | tr -d -)
# current commit hash
PACKAGE_COMMIT := $(shell git log -1 --pretty="%h")
# current commit date minus dashes
PACKAGE_TIMESTAMP := $(shell git log -1 --pretty="%ad" --date=short | tr -d -)

PACKAGE_SERVER=ddr.densho.org/static/$(APP)

SRC_REPO_IDSERVICE=https://github.com/densho/ddr-idservice.git
SRC_REPO_CMDLN=https://github.com/densho/ddr-cmdln.git
SRC_REPO_DEFS=https://github.com/densho/ddr-defs.git

INSTALL_BASE=/opt
INSTALLDIR=$(INSTALL_BASE)/ddr-idservice
INSTALLDIR_CMDLN=$(INSTALLDIR)/ddr-cmdln
INSTALLDIR_DEFS=$(INSTALLDIR)/ddr-defs
REQUIREMENTS=$(INSTALL_PUBLIC)/requirements.txt
DOWNLOADS_DIR=/tmp/$(APP)-install
PIP_CACHE_DIR=$(INSTALL_BASE)/pip-cache

VIRTUALENV=$(INSTALLDIR)/venv/$(APP)
DJANGO_CONF=$(INSTALLDIR)/idservice/idservice/settings.py

CONF_BASE=/etc/ddr
CONF_PRODUCTION=$(CONF_BASE)/$(PROJECT).cfg
CONF_LOCAL=$(CONF_BASE)/$(PROJECT)-local.cfg

SQLITE_BASE=/var/lib/$(PROJECT)
LOG_BASE=/var/log/ddr

MEDIA_BASE=/var/www/$(APP)
MEDIA_ROOT=$(MEDIA_BASE)/media
STATIC_ROOT=$(MEDIA_BASE)/static

SUPERVISOR_GUNICORN_CONF=/etc/supervisor/conf.d/$(APP).conf
NGINX_APP_CONF=/etc/nginx/sites-available/$(APP).conf
NGINX_APP_CONF_LINK=/etc/nginx/sites-enabled/$(APP).conf

MODERNIZR=modernizr-2.6.2.js
JQUERY=jquery-1.11.0.min.js
BOOTSTRAP=bootstrap-3.1.1-dist
ASSETS=ddr-idservice-assets.tar.gz
# wget https://github.com/twbs/bootstrap/releases/download/v3.1.1/bootstrap-3.1.1-dist.zip
# wget http://code.jquery.com/jquery-1.11.0.min.js


DEB_BRANCH := $(shell git rev-parse --abbrev-ref HEAD | tr -d _ | tr -d -)
DEB_ARCH=amd64
DEB_NAME_JESSIE=$(PROJECT)-$(DEB_BRANCH)
DEB_NAME_STRETCH=$(PROJECT)-$(DEB_BRANCH)
# Application version, separator (~), Debian release tag e.g. deb8
# Release tag used because sortable and follows Debian project usage.
DEB_VERSION_JESSIE=$(APP_VERSION)~deb8
DEB_VERSION_STRETCH=$(APP_VERSION)~deb9
DEB_FILE_JESSIE=$(DEB_NAME_JESSIE)_$(DEB_VERSION_JESSIE)_$(DEB_ARCH).deb
DEB_FILE_STRETCH=$(DEB_NAME_STRETCH)_$(DEB_VERSION_STRETCH)_$(DEB_ARCH).deb
DEB_VENDOR=Densho.org
DEB_MAINTAINER=<geoffrey.jost@densho.org>
DEB_DESCRIPTION=Densho Digital Repository ID service
DEB_BASE=opt/ddr-idservice


.PHONY: help


help:
	@echo "--------------------------------------------------------------------------------"
	@echo "ddr-idservice make commands"
	@echo ""
	@echo "Most commands have subcommands (ex: install-ddr-cmdln, restart-supervisor)"
	@echo ""
	@echo "get     - Downloads source, installers, and assets files. Does not install."
	@echo "install - Installs app, config files, and static assets.  Does not download."
	@echo "          IMPORTANT: Run 'adduser ddr' first to install ddr user and group."
	@echo "          Installation instructions: make howto-install"
	@echo "syncdb  - Initialize or update Django app's database tables."
	@echo "reload  - Reloads supervisord and nginx configs"
	@echo "restart - Restarts all servers"
	@echo "stop    - Stops all servers"
	@echo "status  - Server status"
	@echo ""
	@echo "deb       - Makes a DEB package install file."
	@echo "remove    - Removes Debian packages for dependencies."
	@echo "uninstall - Deletes 'compiled' Python files. Leaves build dirs and configs."
	@echo "clean     - Deletes files created while building app, leaves configs."
	@echo ""

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

install: install-prep get-app install-app install-configs

uninstall: uninstall-app uninstall-configs

clean: clean-app


install-prep: ddr-user install-core git-config install-misc-tools

ddr-user:
	-addgroup --gid=1001 ddr
	-adduser --uid=1001 --gid=1001 --home=/home/ddr --shell=/bin/bash ddr
	-addgroup ddr plugdev
	-addgroup ddr vboxsf
	printf "\n\n# ddrlocal: Activate virtualnv on login\nsource $(VIRTUALENV)/bin/activate\n" >> /home/ddr/.bashrc; \

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


install-daemons: install-nginx install-mariadb install-redis

remove-daemons: remove-nginx remove-mariadb remove-redis


install-nginx:
	@echo ""
	@echo "Nginx ------------------------------------------------------------------"
	apt-get --assume-yes install nginx

remove-nginx:
	apt-get --assume-yes remove nginx

install-mariadb:
	@echo ""
	@echo "MariaDB ----------------------------------------------------------------"
	apt-get --assume-yes install mariadb-server mariadb-client libmysqlclient-dev

remove-mariadb:
	apt-get --assume-yes remove mariadb-server mariadb-client libmysqlclient-dev

install-redis:
	@echo ""
	@echo "Redis ------------------------------------------------------------------"
	apt-get --assume-yes install redis-server

remove-redis:
	apt-get --assume-yes remove redis-server


install-virtualenv:
	@echo ""
	@echo "install-virtualenv -----------------------------------------------------"
	apt-get --assume-yes install python-six python-pip python-virtualenv python-dev
	test -d $(VIRTUALENV) || virtualenv --distribute --setuptools $(VIRTUALENV)
	source $(VIRTUALENV)/bin/activate; \
	pip install -U bpython appdirs blessings curtsies greenlet packaging pygments pyparsing setuptools wcwidth
#	virtualenv --relocatable $(VIRTUALENV)  # Make venv relocatable



get-app: get-ddr-defs get-ddr-cmdln get-ddr-idservice

install-app: install-virtualenv install-ddr-cmdln install-ddr-idservice install-configs install-daemons-configs make-static-dirs

uninstall-app: uninstall-ddr-idservice uninstall-ddr-cmdln

clean-app: clean-ddr-idservice clean-ddr-cmdln


get-ddr-defs:
	@echo ""
	@echo "get-ddr-defs -----------------------------------------------------------"
	if test -d $(INSTALLDIR_DEFS); \
	then cd $(INSTALLDIR_DEFS) && git pull; \
	else cd $(INSTALLDIR) && git clone $(SRC_REPO_DEFS); \
	fi


get-ddr-cmdln:
	@echo ""
	@echo "get-ddr-cmdln ----------------------------------------------------------"
	git status | grep "On branch"
	if test -d $(INSTALLDIR_CMDLN); \
	then cd $(INSTALLDIR_CMDLN) && git pull; \
	else cd $(INSTALLDIR) && git clone $(SRC_REPO_CMDLN); \
	fi

setup-ddr-cmdln:
	git status | grep "On branch"
	source $(VIRTUALENV)/bin/activate; \
	cd $(INSTALLDIR_CMDLN)/ddr && python setup.py install

install-ddr-cmdln: install-virtualenv
	@echo ""
	@echo "install-ddr-cmdln ------------------------------------------------------"
	git status | grep "On branch"
	apt-get --assume-yes install git-core git-annex libxml2-dev libxslt1-dev libz-dev pmount udisks2
	source $(VIRTUALENV)/bin/activate; \
	cd $(INSTALLDIR_CMDLN)/ddr && python setup.py install
	source $(VIRTUALENV)/bin/activate; \
	cd $(INSTALLDIR_CMDLN) && pip install -U -r $(INSTALLDIR_CMDLN)/requirements.txt

uninstall-ddr-cmdln: install-virtualenv
	@echo ""
	@echo "uninstall-ddr-cmdln ----------------------------------------------------"
	source $(VIRTUALENV)/bin/activate; \
	cd $(INSTALLDIR_CMDLN) && pip uninstall -y -r $(INSTALLDIR_CMDLN)/requirements.txt

clean-ddr-cmdln:
	-rm -Rf $(INSTALL_CMDLN)/ddr/build
	-rm -Rf $(INSTALL_CMDLN)/ddr/ddr_cmdln.egg-info
	-rm -Rf $(INSTALL_CMDLN)/ddr/dist


get-ddr-idservice:
	@echo ""
	@echo "get-ddr-idservice ----------------------------------------------------------"
	git status | grep "On branch"
	git pull

install-ddr-idservice: install-virtualenv
	@echo ""
	@echo "install-ddr-idservice ------------------------------------------------------"
	apt-get --assume-yes install sqlite3 supervisor
	source $(VIRTUALENV)/bin/activate; \
	cd $(INSTALLDIR) && pip install -U --download-cache=$(PIP_CACHE_DIR) -r $(INSTALLDIR)/requirements.txt
# logs dir
	-mkdir $(LOG_BASE)
	chown -R $(USER).root $(LOG_BASE)
	chmod -R 755 $(LOG_BASE)
# sqlite db dir
	-mkdir $(SQLITE_BASE)
	chown -R $(USER).root $(SQLITE_BASE)
	chmod -R 755 $(SQLITE_BASE)

uninstall-ddr-idservice:
	@echo ""
	@echo "uninstall-ddr-idservice ----------------------------------------------------"
	source $(VIRTUALENV)/bin/activate; \
	cd $(INSTALLDIR) && pip uninstall -y -r $(INSTALLDIR)/requirements.txt

clean-ddr-idservice:
	-rm -Rf $(VIRTUALENV)
	-rm -Rf $(INSTALLDIR)/*.deb


migrate:
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
	chown -R ddr.root $(LOG_BASE)
	chmod -R 755 $(LOG_BASE)


install-configs:
	@echo ""
	@echo "installing configs --------------------------------------------------"
	-mkdir $(CONF_BASE)
# app settings
	cp $(INSTALLDIR)/conf/idservice.cfg $(CONF_PRODUCTION)
	touch $(CONF_LOCAL)
	chown root.root $(CONF_PRODUCTION)
	chown root.ddr $(CONF_LOCAL)
	chmod 644 $(CONF_PRODUCTION)
	chmod 640 $(CONF_LOCAL)
# django settings
	cp $(INSTALLDIR)/conf/settings.py $(DJANGO_CONF)
	chown root.root $(DJANGO_CONF)
	chmod 644 $(DJANGO_CONF)

uninstall-configs:
	-rm $(CONF_PRODUCTION)
	-rm $(CONF_LOCAL)
	-rm $(DJANGO_CONF)

install-daemons-configs:
	@echo ""
	@echo "daemon configs ------------------------------------------------------"
## nginx settings
# 	cp $(INSTALLDIR)/conf/nginx.conf $(NGINX_APP_CONF)
# 	chown root.root $(NGINX_APP_CONF)
# 	chmod 644 $(NGINX_APP_CONF)
# 	-ln -s $(NGINX_APP_CONF) $(NGINX_APP_CONF_LINK)
# 	-rm /etc/nginx/sites-enabled/default
# supervisord
	cp $(INSTALLDIR)/conf/supervisor.conf $(SUPERVISOR_GUNICORN_CONF)
	chown root.root $(SUPERVISOR_GUNICORN_CONF)
	chmod 644 $(SUPERVISOR_GUNICORN_CONF)

uninstall-daemons-configs:
	-rm $(NGINX_APP_CONF)
	-rm $(NGINX_APP_CONF_LINK)
	-rm $(SUPERVISOR_GUNICORN_CONF)


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


# http://fpm.readthedocs.io/en/latest/
# https://stackoverflow.com/questions/32094205/set-a-custom-install-directory-when-making-a-deb-package-with-fpm
# https://brejoc.com/tag/fpm/
deb: deb-jessie deb-stretch

# deb-jessie and deb-stretch are identical
deb-jessie:
	@echo ""
	@echo "DEB packaging (jessie) -------------------------------------------------"
	-rm -Rf $(DEB_FILE_JESSIE)
	virtualenv --relocatable $(VIRTUALENV)  # Make venv relocatable
	fpm   \
	--verbose   \
	--input-type dir   \
	--output-type deb   \
	--name $(DEB_NAME_JESSIE)   \
	--version $(DEB_VERSION_JESSIE)   \
	--package $(DEB_FILE_JESSIE)   \
	--url "$(GIT_SOURCE_URL)"   \
	--vendor "$(DEB_VENDOR)"   \
	--maintainer "$(DEB_MAINTAINER)"   \
	--description "$(DEB_DESCRIPTION)"   \
	--depends "libmysqlclient-dev"   \
	--depends "redis-server"   \
	--depends "sqlite3"   \
	--depends "supervisor"   \
	--depends "nginx"   \
	--deb-recommends "mariadb-client"   \
	--deb-suggests "mariadb-server"   \
	--after-install "bin/fpm-mkdir-log.sh"   \
	--chdir $(INSTALLDIR)   \
	conf/idservice.cfg=etc/ddr/$(APP).cfg   \
	bin=$(DEB_BASE)   \
	conf=$(DEB_BASE)   \
	COPYRIGHT=$(DEB_BASE)   \
	ddr-cmdln=$(DEB_BASE)   \
	ddr-defs=$(DEB_BASE)   \
	.git=$(DEB_BASE)   \
	.gitignore=$(DEB_BASE)   \
	idservice=$(DEB_BASE)   \
	INSTALL.rst=$(DEB_BASE)   \
	LICENSE=$(DEB_BASE)   \
	Makefile=$(DEB_BASE)   \
	README.rst=$(DEB_BASE)   \
	requirements.txt=$(DEB_BASE)   \
	venv=$(DEB_BASE)   \
	venv/$(APP)/lib/python2.7/site-packages/rest_framework/static/rest_framework=$(STATIC_ROOT)  \
	VERSION=$(DEB_BASE)

# deb-jessie and deb-stretch are identical
deb-stretch:
	@echo ""
	@echo "DEB packaging (stretch) ------------------------------------------------"
	-rm -Rf $(DEB_FILE_STRETCH)
	virtualenv --relocatable $(VIRTUALENV)  # Make venv relocatable
	fpm   \
	--verbose   \
	--input-type dir   \
	--output-type deb   \
	--name $(DEB_NAME_STRETCH)   \
	--version $(DEB_VERSION_STRETCH)   \
	--package $(DEB_FILE_STRETCH)   \
	--url "$(GIT_SOURCE_URL)"   \
	--vendor "$(DEB_VENDOR)"   \
	--maintainer "$(DEB_MAINTAINER)"   \
	--description "$(DEB_DESCRIPTION)"   \
	--depends "libmysqlclient-dev"   \
	--depends "redis-server"   \
	--depends "sqlite3"   \
	--depends "supervisor"   \
	--depends "nginx"   \
	--deb-recommends "mariadb-client"   \
	--deb-suggests "mariadb-server"   \
	--after-install "bin/fpm-mkdir-log.sh"   \
	--chdir $(INSTALLDIR)   \
	conf/idservice.cfg=etc/ddr/$(APP).cfg   \
	bin=$(DEB_BASE)   \
	conf=$(DEB_BASE)   \
	COPYRIGHT=$(DEB_BASE)   \
	ddr-cmdln=$(DEB_BASE)   \
	ddr-defs=$(DEB_BASE)   \
	.git=$(DEB_BASE)   \
	.gitignore=$(DEB_BASE)   \
	idservice=$(DEB_BASE)   \
	INSTALL.rst=$(DEB_BASE)   \
	LICENSE=$(DEB_BASE)   \
	Makefile=$(DEB_BASE)   \
	README.rst=$(DEB_BASE)   \
	requirements.txt=$(DEB_BASE)   \
	venv=$(DEB_BASE)   \
	venv/$(APP)/lib/python2.7/site-packages/rest_framework/static/rest_framework=$(STATIC_ROOT)  \
	VERSION=$(DEB_BASE)
