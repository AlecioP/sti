all: dl-child-projects build-framework

build-framework:
	@echo "Now build CTS2 Framework"
#	cd ./cts2-framework/ && make tomcat && make liferay && make stop && make cts2-plugin

dl-child-projects:
	@if ! test -d "./sti-service/" ; then git clone https://github.com/aleciop/sti-service ; fi
	@if ! test -d "./sti-cts2-portlets-build/" ; then git clone https://github.com/AlecioP/sti-cts2-portlets-build ; fi

install-postgresql:
	sudo yum install postgresql-server postgresql-contrib
	sudo postgresql-setup initdb
	sudo systemctl enable postgresql
	sudo systemctl start postgresql
# Last lucene version compatible with 6.x core
SOLR_V=7.7.3
SOLR_ARCHIVE=solr-$(SOLR_V).tgz

solr-start:
	-sudo service solr start
solr-status:
	-sudo service solr status
solr-stop:
	-sudo service solr stop

# Depends on framework target cause creates Tomcat user
solr: build-framework
	@$(call download_lib,$(SOLR_ARCHIVE),"https://archive.apache.org/dist/lucene/solr/$(SOLR_V)/$(SOLR_ARCHIVE)") 
	which lsof && echo 'lsof installed' || sudo yum install lsof
	@if test -d "/etc/init.d" ; then echo "Directory /etc/init.d already exists. Install of chkconfig could fail" ; fi 
	which chkconfig && echo 'chkconfig installed' || sudo yum install chkconfig
	@if ! test -f "./install_solr_service.sh" ; then tar xzf /tmp/$(SOLR_ARCHIVE) solr-$(SOLR_V)/bin/install_solr_service.sh --strip-components=2 ; fi
	if ! test -d "/etc/init.d" ; then sudo mkdir /etc/init.d/ ; fi
# -u to run as USER 'tomcat' ; -n to avoid start after install
	sudo bash ./install_solr_service.sh /tmp/$(SOLR_ARCHIVE) -u tomcat -n

	sudo chown -R tomcat: /opt/solr
	sudo chown -R tomcat: /opt/solr-$(SOLR_V)

solr-import-indexes: solr-stop #solr
	cd ./sti-service/ && make  AM_DEBUG=false

test:
	echo $(SOLR_ARCHIVE:.tgz=)

clean-solr:
	-sudo service solr stop
	-sudo rm /opt/solr
	-sudo rm -r /opt/solr*
	-sudo rm -r /var/solr
	-sudo chkconfig --del solr
	-sudo rm /etc/init.d/solr
	-sudo rm -r /etc/default/solr.in.sh
######## Functions ##########

# Procedure download_lib
# Parameters :
# $(1) -> Filename
# $(2) -> URL
define download_lib
	if [ -f "/tmp/$(1)" ]; then echo "$(1) already downloaded"; else wget $(2) -P /tmp; fi
endef