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

ifeq ($(DEBIAN_CODENAME), buster)
	PYTHON_VERSION=3.7
endif

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
REQUIREMENTS=$(INSTALLDIR)/requirements.txt
PIP_CACHE_DIR=$(INSTALL_BASE)/pip-cache

CWD := $(shell pwd)
INSTALL_IDS=/opt/ddr-idservice
INSTALL_CMDLN=/opt/ddr-cmdln
INSTALL_CMDLN_ASSETS=/opt/ddr-cmdln/ddr-cmdln-assets
INSTALL_DEFS=/opt/ddr-defs

VIRTUALENV=$(INSTALL_IDS)/venv/$(APP)

CONF_BASE=/etc/ddr
CONF_PRODUCTION_IDS=$(CONF_BASE)/ddridservice.cfg
CONF_LOCAL_IDS=$(CONF_BASE)/ddridservice-local.cfg
CONF_PRODUCTION_CMDLN=$(CONF_BASE)/ddrlocal.cfg
CONF_LOCAL_CMDLN=$(CONF_BASE)/ddrlocal-local.cfg

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

TGZ_BRANCH := $(shell python3 bin/package-branch.py)
TGZ_FILE=$(APP)_$(APP_VERSION)
TGZ_DIR=$(INSTALL_IDS)/$(TGZ_FILE)
TGZ_IDS=$(TGZ_DIR)/ddr-idservice
TGZ_CMDLN=$(TGZ_DIR)/ddr-cmdln
TGZ_CMDLN_ASSETS=$(TGZ_DIR)/ddr-cmdln/ddr-cmdln-assets
TGZ_DEFS=$(TGZ_DIR)/ddr-defs
TGZ_STATIC=$(TGZ_DIR)/ddr-idservice/static

DEB_BRANCH := $(shell git rev-parse --abbrev-ref HEAD | tr -d _ | tr -d -)
DEB_ARCH=amd64
DEB_NAME_BUSTER=$(APP)-$(DEB_BRANCH)
# Application version, separator (~), Debian release tag e.g. deb8
# Release tag used because sortable and follows Debian project usage.
DEB_VERSION_BUSTER=$(APP_VERSION)~deb10
DEB_FILE_BUSTER=$(DEB_NAME_BUSTER)_$(DEB_VERSION_BUSTER)_$(DEB_ARCH).deb
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
	@echo "- # git clone https://github.com/densho/ddr-idservice.git $(INSTALL_IDS)"
	@echo "- # cd $(INSTALL_IDS)"
	@echo "- # make get"
	@echo "- # make install"
	@echo "- # make syncdb"
	@echo "- # make restart"


get: get-app

install: install-prep get-app install-app install-configs

test: test-app

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
	apt-get --assume-yes install mariadb-server mariadb-client libmariadbclient-dev

remove-mariadb:
	apt-get --assume-yes remove mariadb-server mariadb-client libmariadbclient-dev

install-redis:
	@echo ""
	@echo "Redis ------------------------------------------------------------------"
	apt-get --assume-yes install redis-server

remove-redis:
	apt-get --assume-yes remove redis-server


install-virtualenv:
	@echo ""
	@echo "install-virtualenv -----------------------------------------------------"
	apt-get --assume-yes install python3-pip python3-venv
	python3 -m venv $(VIRTUALENV)

install-setuptools: install-virtualenv
	@echo ""
	@echo "install-setuptools -----------------------------------------------------"
	apt-get --assume-yes install python3-dev
	source $(VIRTUALENV)/bin/activate; \
	pip3 install -U --cache-dir=$(PIP_CACHE_DIR) setuptools



get-app: get-ddr-defs get-ddr-cmdln get-ddr-cmdln-assets get-ddr-idservice

install-app: install-virtualenv install-ddr-cmdln install-ddr-idservice install-configs install-daemons-configs make-static-dirs

test-app: test-ddr-cmdln test-ddr-idservice

uninstall-app: uninstall-ddr-idservice uninstall-ddr-cmdln

clean-app: clean-ddr-idservice clean-ddr-cmdln


get-ddr-defs:
	@echo ""
	@echo "get-ddr-defs -----------------------------------------------------------"
	git status | grep "On branch"
	if test -d $(INSTALL_DEFS); \
	then cd $(INSTALL_DEFS) && git pull; \
	else git clone $(SRC_REPO_DEFS) $(INSTALL_DEFS); \
	fi


get-ddr-cmdln:
	@echo ""
	@echo "get-ddr-cmdln ----------------------------------------------------------"
	git status | grep "On branch"
	if test -d $(INSTALL_CMDLN); \
	then cd $(INSTALL_CMDLN) && git pull; \
	else git clone $(SRC_REPO_CMDLN) $(INSTALL_CMDLN); \
	fi

get-ddr-cmdln-assets:
	@echo ""
	@echo "get-ddr-cmdln-assets ---------------------------------------------------"
	if test -d $(INSTALL_CMDLN_ASSETS); \
	then cd $(INSTALL_CMDLN_ASSETS) && git pull; \
	else git clone $(SRC_REPO_CMDLN_ASSETS) $(INSTALL_CMDLN_ASSETS); \
	fi

setup-ddr-cmdln:
	git status | grep "On branch"
	source $(VIRTUALENV)/bin/activate; \
	cd $(INSTALL_CMDLN)/ddr && python setup.py install

install-ddr-cmdln: install-virtualenv
	@echo ""
	@echo "install-ddr-cmdln ------------------------------------------------------"
	git status | grep "On branch"
	apt-get --assume-yes install git-core git-annex libxml2-dev libxslt1-dev libz-dev pmount udisks2
	source $(VIRTUALENV)/bin/activate; \
	cd $(INSTALL_CMDLN)/ddr; python setup.py install
	source $(VIRTUALENV)/bin/activate; \
	pip3 install -U --cache-dir=$(PIP_CACHE_DIR) -r $(INSTALL_CMDLN)/requirements.txt

test-ddr-cmdln:
	@echo ""
	@echo "test-ddr-cmdln ---------------------------------------------------------"
	source $(VIRTUALENV)/bin/activate; \
	cd $(INSTALL_CMDLN)/; pytest --disable-warnings ddr/tests/test_identifier.py
# 	source $(VIRTUALENV)/bin/activate; \
# 	cd $(INSTALL_CMDLN)/; pytest --disable-warnings ddr/tests/test_idservice.py

uninstall-ddr-cmdln: install-virtualenv
	@echo ""
	@echo "uninstall-ddr-cmdln ----------------------------------------------------"
	source $(VIRTUALENV)/bin/activate; \
	cd $(INSTALL_CMDLN)/ddr && pip3 uninstall -y -r requirements.txt

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
	apt-get --assume-yes install default-libmysqlclient-dev mariadb-client sqlite3 supervisor
	source $(VIRTUALENV)/bin/activate; \
	cd $(INSTALL_IDS) && pip3 install -U --cache-dir=$(PIP_CACHE_DIR) -r $(INSTALL_IDS)/requirements.txt
# logs dir
	-mkdir $(LOG_BASE)
	chown -R $(USER).root $(LOG_BASE)
	chmod -R 755 $(LOG_BASE)
	touch $(LOG_BASE)/idservice.log
	chown $(USER).$(USER) $(LOG_BASE)/idservice.log
	chmod 644 $(LOG_BASE)/idservice.log
# sqlite db dir
	-mkdir $(SQLITE_BASE)
	chown -R $(USER).root $(SQLITE_BASE)
	chmod -R 755 $(SQLITE_BASE)

test-ddr-idservice:
	@echo ""
	@echo "test-ddr-idservice -----------------------------------------------------"
	source $(VIRTUALENV)/bin/activate; \
	cd $(INSTALL_IDS)/; pytest --disable-warnings --reuse-db idservice/

shell:
	source $(VIRTUALENV)/bin/activate; \
	python idservice/manage.py shell

runserver:
	source $(VIRTUALENV)/bin/activate; \
	python idservice/manage.py runserver 0.0.0.0:8082

uninstall-ddr-idservice:
	@echo ""
	@echo "uninstall-ddr-idservice ----------------------------------------------------"
	source $(VIRTUALENV)/bin/activate; \
	cd $(INSTALL_IDS) && pip3 uninstall -y -r $(INSTALL_IDS)/requirements.txt

clean-ddr-idservice:
	-rm -Rf $(VIRTUALENV)
	-rm -Rf $(INSTALL_IDS)/*.deb


migrate:
	source $(VIRTUALENV)/bin/activate; \
	cd $(INSTALL_IDS)/idservice && python manage.py migrate --noinput
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
	cd $(INSTALL_IDS)/idservice; python ./bin/git-checkout-branch.py $(BRANCH)


make-static-dirs:
	-mkdir $(MEDIA_BASE)
	-mkdir $(STATIC_ROOT)
	-mkdir $(STATIC_ROOT)/js
	chown -R $(USER).root $(MEDIA_BASE)
	chmod -R 755 $(MEDIA_BASE)
# static
	source $(VIRTUALENV)/bin/activate; \
	cd $(INSTALL_IDS)/idservice && python manage.py collectstatic --noinput
# running collectstatic as root changes ownership; change back to ddr
	chown -R ddr.root $(LOG_BASE)
	chmod -R 755 $(LOG_BASE)


install-configs:
	@echo ""
	@echo "installing configs --------------------------------------------------"
	-mkdir $(CONF_BASE)
# app settings
	cp $(INSTALL_IDS)/conf/idservice.cfg $(CONF_PRODUCTION_IDS)
	cp $(INSTALL_CMDLN)/conf/ddrlocal.cfg $(CONF_PRODUCTION_CMDLN)
	touch $(CONF_LOCAL_IDS)
	touch $(CONF_LOCAL_CMDLN)
	chown root.root $(CONF_PRODUCTION_IDS)
	chown root.root $(CONF_PRODUCTION_CMDLN)
	chown root.ddr $(CONF_LOCAL_IDS)
	chown root.ddr $(CONF_LOCAL_CMDLN)
	chmod 644 $(CONF_PRODUCTION_IDS)
	chmod 644 $(CONF_PRODUCTION_CMDLN)
	chmod 640 $(CONF_LOCAL_IDS)
	chmod 640 $(CONF_LOCAL_CMDLN)

uninstall-configs:
	-rm $(CONF_PRODUCTION_IDS)
	-rm $(CONF_PRODUCTION_CMDLN)
	-rm $(CONF_LOCAL)
	-rm $(DJANGO_CONF)

install-daemons-configs:
	@echo ""
	@echo "daemon configs ------------------------------------------------------"
## nginx settings
# 	cp $(INSTALL_IDS)/conf/nginx.conf $(NGINX_APP_CONF)
# 	chown root.root $(NGINX_APP_CONF)
# 	chmod 644 $(NGINX_APP_CONF)
# 	-ln -s $(NGINX_APP_CONF) $(NGINX_APP_CONF_LINK)
# 	-rm /etc/nginx/sites-enabled/default
# supervisord
	cp $(INSTALL_IDS)/conf/supervisor.conf $(SUPERVISOR_GUNICORN_CONF)
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
	cd $(INSTALL_IDS) && git status


# http://fpm.readthedocs.io/en/latest/
install-fpm:
	@echo "install-fpm ------------------------------------------------------------"
	apt-get install --assume-yes ruby ruby-dev rubygems build-essential
	gem install --no-ri --no-rdoc fpm


tgz-local:
	rm -Rf $(TGZ_DIR)
	git clone $(INSTALL_IDS) $(TGZ_IDS)
	git clone $(INSTALL_CMDLN) $(TGZ_CMDLN)
	git clone $(INSTALL_CMDLN_ASSETS) $(TGZ_CMDLN_ASSETS)
	git clone $(INSTALL_DEFS) $(TGZ_DEFS)
	cd $(TGZ_IDS); git checkout develop; git checkout master
	cd $(TGZ_CMDLN); git checkout develop; git checkout master
	cd $(TGZ_CMDLN_ASSETS); git checkout develop; git checkout master
	cd $(TGZ_DEFS); git checkout develop; git checkout master
	tar czf $(TGZ_FILE).tgz $(TGZ_FILE)
	rm -Rf $(TGZ_DIR)

tgz:
	rm -Rf $(TGZ_DIR)
	git clone $(SRC_REPO_IDS) $(TGZ_IDS)
	git clone $(SRC_REPO_CMDLN) $(TGZ_CMDLN)
	git clone $(SRC_REPO_CMDLN_ASSETS) $(TGZ_CMDLN_ASSETS)
	git clone $(SRC_REPO_DEFS) $(TGZ_DEFS)
	cd $(TGZ_IDS); git checkout develop; git checkout master
	cd $(TGZ_CMDLN); git checkout develop; git checkout master
	cd $(TGZ_CMDLN_ASSETS); git checkout develop; git checkout master
	cd $(TGZ_DEFS); git checkout develop; git checkout master
	tar czf $(TGZ_FILE).tgz $(TGZ_FILE)
	rm -Rf $(TGZ_DIR)


# http://fpm.readthedocs.io/en/latest/
# https://stackoverflow.com/questions/32094205/set-a-custom-install-directory-when-making-a-deb-package-with-fpm
# https://brejoc.com/tag/fpm/
deb: deb-buster

deb-buster:
	@echo ""
	@echo "DEB packaging (buster) ------------------------------------------------"
	-rm -Rf $(DEB_FILE_BUSTER)
	fpm   \
	--verbose   \
	--input-type dir   \
	--output-type deb   \
	--name $(DEB_NAME_BUSTER)   \
	--version $(DEB_VERSION_BUSTER)   \
	--package $(DEB_FILE_BUSTER)   \
	--url "$(GIT_SOURCE_URL)"   \
	--vendor "$(DEB_VENDOR)"   \
	--maintainer "$(DEB_MAINTAINER)"   \
	--description "$(DEB_DESCRIPTION)"   \
	--depends "default-libmysqlclient-dev"   \
	--depends "redis-server"   \
	--depends "sqlite3"   \
	--depends "supervisor"   \
	--depends "nginx"   \
	--deb-recommends "mariadb-client"   \
	--deb-suggests "mariadb-server"   \
	--after-install "bin/fpm-mkdir-log.sh"   \
	--chdir $(INSTALL_IDS)   \
	conf/idservice.cfg=etc/ddr/ddridservice.cfg   \
	bin=$(DEB_BASE)   \
	conf=$(DEB_BASE)   \
	COPYRIGHT=$(DEB_BASE)   \
	../ddr-cmdln=opt   \
	../ddr-defs=opt   \
	.git=$(DEB_BASE)   \
	.gitignore=$(DEB_BASE)   \
	idservice=$(DEB_BASE)   \
	INSTALL.rst=$(DEB_BASE)   \
	LICENSE=$(DEB_BASE)   \
	Makefile=$(DEB_BASE)   \
	README.rst=$(DEB_BASE)   \
	requirements.txt=$(DEB_BASE)   \
	venv=$(DEB_BASE)   \
	venv/$(APP)/lib/python$(PYTHON_VERSION)/site-packages/rest_framework/static/rest_framework=$(STATIC_ROOT)  \
	VERSION=$(DEB_BASE)

deb-buster:
	@echo ""
	@echo "DEB packaging (buster) -------------------------------------------------"
	-rm -Rf $(DEB_FILE_BUSTER)
	fpm   \
	--verbose   \
	--input-type dir   \
	--output-type deb   \
	--name $(DEB_NAME_BUSTER)   \
	--version $(DEB_VERSION_BUSTER)   \
	--package $(DEB_FILE_BUSTER)   \
	--url "$(GIT_SOURCE_URL)"   \
	--vendor "$(DEB_VENDOR)"   \
	--maintainer "$(DEB_MAINTAINER)"   \
	--description "$(DEB_DESCRIPTION)"   \
	--depends "default-libmysqlclient-dev"   \
	--depends "redis-server"   \
	--depends "sqlite3"   \
	--depends "supervisor"   \
	--depends "nginx"   \
	--deb-recommends "mariadb-client"   \
	--deb-suggests "mariadb-server"   \
	--after-install "bin/fpm-mkdir-log.sh"   \
	--chdir $(INSTALL_IDS)   \
	conf/idservice.cfg=etc/ddr/ddridservice.cfg   \
	bin=$(DEB_BASE)   \
	conf=$(DEB_BASE)   \
	COPYRIGHT=$(DEB_BASE)   \
	../ddr-cmdln=opt   \
	../ddr-defs=opt   \
	.git=$(DEB_BASE)   \
	.gitignore=$(DEB_BASE)   \
	idservice=$(DEB_BASE)   \
	INSTALL.rst=$(DEB_BASE)   \
	LICENSE=$(DEB_BASE)   \
	Makefile=$(DEB_BASE)   \
	README.rst=$(DEB_BASE)   \
	requirements.txt=$(DEB_BASE)   \
	venv=$(DEB_BASE)   \
	venv/$(APP)/lib/python$(PYTHON_VERSION)/site-packages/rest_framework/static/rest_framework=$(STATIC_ROOT)  \
	VERSION=$(DEB_BASE)
