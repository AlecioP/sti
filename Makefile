ifndef PSQL_PW
$(error Define a password for the user running Postgresql Server. Use argument PSQL_PW=)
endif



all: dl-child-projects build-framework solr sti-service

build-framework:
	@echo "Now build CTS2 Framework"
#	cd ./cts2-framework/ && make tomcat && make liferay && make stop && make cts2-plugin

dl-child-projects:
	@if ! test -d "./sti-service/" ; then git clone https://github.com/aleciop/sti-service ; fi
	@if ! test -d "./sti-cts2-portlets-build/" ; then git clone https://github.com/AlecioP/sti-cts2-portlets-build ; fi

# Reference https://www.hostinger.com/tutorials/how-to-install-postgresql-on-centos-7/
# Initializing database in '/var/lib/pgsql/data'
# Initialized, logs are in '/var/lib/pgsql/initdb_postgresql.log'
#
# Created symlink /etc/systemd/system/multi-user.target.wants/postgresql.service -> /usr/lib/systemd/system/postgresql.service
install-postgresql:
	@if which postgres 2>/dev/null && echo 'Postgres already installed' || (\
	sudo yum install postgresql-server postgresql-contrib && \
	sudo postgresql-setup initdb && \
	sudo systemctl enable postgresql && \
	sudo systemctl start postgresql && \
	(echo $(PSQL_PW) ; echo $(PSQL_PW) ) | sudo passwd postgres )

PG_HOME=/var/lib/pgsql
DUMPS_ARCHIVE=dump_dati_base.zip
DUMPS_LINK=http://cosenza.iit.cnr.it/repo/sti/dati_base/$(DUMPS_ARCHIVE)

db-setup:
	$(call download_lib,$(DUMPS_ARCHIVE),"$(DUMPS_LINK)")
	sudo unzip -q /tmp/$(DUMPS_ARCHIVE) -d $(PG_HOME)
	sudo chown -R postgres: $(PG_HOME)/$(DUMPS_ARCHIVE:.zip=)/
# Download and copy script sti_service.sql and sti_import.sql in postgres home directory
	su postgres -c ' \
		psql -c "create user sti_cts2 with encrypted passwd \'$(PSQL_PW)\' nosuperuser nocreatedb nocreaterole login " ' && \
		psql -c "create database sti_import" && \
		psql -c "create database sti_service" && \
		psql sti_service < $(PG_HOME)/$(DUMPS_ARCHIVE:.zip=)/sti_service.sql && \
		psql sti_import < $(PG_HOME)/$(DUMPS_ARCHIVE:.zip=)/sti_import.sql \
	'
	su postgres -c " \
		sed -i '1s/^/local sti_import sti_cts2   password\n/' $(PG_HOME)/data/pg_hba.conf && \
		sed -i '1s/^/local sti_service sti_cts2   password\n/' $(PG_HOME)/data/pg_hba.conf && \
		sed -i '1s/^/host sti_import sti_cts2 ::1/128 password\n/' $(PG_HOME)/data/pg_hba.conf && \
		sed -i '1s/^/local sti_import sti_cts2 ::1/128 password\n/' $(PG_HOME)/data/pg_hba.conf \
	"
	sudo systemctl reload postgres
	sudo systemctl restart postgres

	$(call set_prop,/opt/tomcat/sti-dev.properties,db\.sti\.username,sti_cts2)
	$(call set_prop,/opt/tomcat/sti-dev.properties,db\.sti\.password,$(PSQL_PW))
	$(call set_prop,/opt/tomcat/sti-dev.properties,cts2\.sti\.import\.username,sti_cts2)
	$(call set_prop,/opt/tomcat/sti-dev.properties,cts2\.sti\.import\.password,$(PSQL_PW))

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

sti-service: #solr
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

KETTLE_PROP_PATH=/opt/tomcat/.kettle/kettle.properties

PDI_USER_HOME=/opt/pdi
PDI_VERSION=ce-9.3.0.0-428
PDI_ARCHIVE=pdi-$(PDI_VERSION).zip
PDI_REMOTE=https://privatefilesbucket-community-edition.s3.us-west-2.amazonaws.com/$(PDI_ARCHIVE)

ifneq (,$(findstring ce,$(PDI_VERSION)))
USING_PDI_COMMUNITY=true
endif


ifndef USING_PDI_COMMUNITY
	ifndef PDI_PW
$(error Define a password for the user running Pentaho Data Integration Server. Use argument PDI_PW=)
	endif
pentaho:
# Reference 
# https://help.hitachivantara.com/Documentation/Pentaho/9.4/Setup/Prepare_your_Linux_environment_for_a_manual_installation
# https://help.hitachivantara.com/Documentation/Pentaho/9.4/Setup/Manual_installation
	sudo useradd -m $(PDI_USER_HOME) -U -s /bin/bash pentaho
	su root -c ' \
		usermod -aG wheel pentaho && \
		id pentaho \
	'
	(echo $(PDI_PW) ; echo $(PDI_PW) ) | sudo passwd pentaho
	su pentaho -c ' \
		mkdir -p ~/pentaho/server/pentaho-server && \
		mkdir -p ~/.pentaho/ \
	'
	su pentaho -c ' \
		echo 'export JAVA_HOME=$$(which java)' >~/.bashrc \
	'
# Webapp-server/ -> latest/ -> apache-tomcat-<version>/
	sudo ln -s "/opt/tomcat/latest" $(PDI_USER_HOME)/pentaho/server/pentaho-server/tomcat
# Should do more stuff (download archives, extract, move in tomcat directory, connect db)
# But since missing commercial license: Using community edition
else
pentaho:
# Reference 
# https://www.hitachivantara.com/en-us/pdf/white-paper/pentaho-ce-installation-guide-on-linux-operating-system-whitepaper.pdf.
# https://github.com/pentaho/pentaho-kettle
# For plugins
# https://help.hitachivantara.com/Documentation/Pentaho/7.0/0F0/Install_the_Pentaho_Client_Tools/Install_PDI_Tools_and_Plugins#Installing_PDI_Plugins
# https://github.com/pentaho/pdi-sdk-plugins
# https://raw.githubusercontent.com/pentaho/maven-parent-poms/master/maven-support-files/settings.xml
# For kitchen
# https://help.hitachivantara.com/Documentation/Pentaho/7.0/0L0/0Y0/070
	@$(call download_lib,$(PDI_ARCHIVE),"$(PDI_REMOTE)") 
	su tomcat -c ' \
		mkdir $(PDI_USER_HOME) 2>/dev/null || \
		(echo "Dir $(PDI_USER_HOME) already exists. Deleting and recreating " && \
		rm -r $(PDI_USER_HOME) && \
		mkdir $(PDI_USER_HOME)) \
	'
	sudo unzip -q /tmp/$(PDI_ARCHIVE) -d $(PDI_USER_HOME)
	sudo chown -R tomcat: $(PDI_USER_HOME)/data-integration
	su tomcat -c 'mkdir $(PDI_USER_HOME)/sti-jobs/'
	sudo cp -r ./sti-cts2-portlets-build/extra/ETL/Trasformazioni_kettle/*   $(PDI_USER_HOME)/sti-jobs/
	sudo chown -R tomcat: $(PDI_USER_HOME)/sti-jobs/

	$(call set_prop,/opt/tomcat/sti-dev.properties,kitchen\.executable\.path,$(subst /,\/,$(PDI_USER_HOME))\/data-integration\/kitchen\.sh)
	$(call set_prop,/opt/tomcat/sti-dev.properties,kitchen\.job\.loinc,$(subst /,\/,$(PDI_USER_HOME))\/sti-jobs\/LOINC_definitivo\/POPOLA_LOINC\.kjb)
	$(call set_prop,/opt/tomcat/sti-dev.properties,kitchen\.job\.aic,$(subst /,\/,$(PDI_USER_HOME))\/sti-jobs\/ATC_AIC\/POPOLA_AIC\.kjb)
	$(call set_prop,/opt/tomcat/sti-dev.properties,kitchen\.job\.atc,$(subst /,\/,$(PDI_USER_HOME))\/sti-jobs\/ATC_AIC\/POPOLA_ATC\.kjb)
	$(call set_prop,/opt/tomcat/sti-dev.properties,kitchen\.job\.mapping\.atc\.aic,$(subst /,\/,$(PDI_USER_HOME))\/sti-jobs\/ATC_AIC\/POPOLA_FARMACI_EQUIVALENTI_MAPPING_ATC_AIC\.kjb)

# Usually kettle.properties file should be created by kettle itself when PDI is started for the first time 
# The file will be created under the home directory of the user running kettle in a subdirectory named '.kettle'
# Therefore the full path should be /opt/tomcat/.kettle/kettle.properties

	if test -f $(KETTLE_PROP_PATH) ; then sudo rm $(KETTLE_PROP_PATH) ; fi
	su tomcat -c 'touch $(KETTLE_PROP_PATH)'
	su tomcat -c 'echo "HOST_NAME=localhost" >> $(KETTLE_PROP_PATH)'
	su tomcat -c 'echo "DATABASE_NAME=sti_import" >> $(KETTLE_PROP_PATH)'
	su tomcat -c 'echo "PORT_NUMBER=5432" >> $(KETTLE_PROP_PATH)'
# TODO set appropriate password and user (maybe use PSQL_PW variable)
	su tomcat -c 'echo "DB_USER=" >> $(KETTLE_PROP_PATH)'
	su tomcat -c 'echo "DB_PASSWORD=" >> $(KETTLE_PROP_PATH)'

endif

# Every workflow in package <it.linksmt.cts2.plugin.sti.service.changeset.impl> of 
# repo sti-service uses StiAppConfig class defined in both
# sti-cts2-portlets-build : <it.linksmt.cts2.portlet.search>
# and 
# sti-service : <it.linksmt.cts2.plugin.sti.service.util>
#
# In both these classes <System.getenv("STI_CTS2_CONFIG");> is called.
# This means the application reads from environemnt the path to the actual 
# file containing all of configuration variables.
# The file is loaded into a <java.util.Properties> object from which every 
# class importing <StiAppConfig> can read the needed properties.
# 
# For example in class <NewVersionAicWorkflow> the variable POPOLA_AIC
# is accessed using StiAppConfig and defines the path of a specific Kettle Job file

SITEID_LPORTAL=21690
GROUPID_LPORTAL=$(SITEID_LPORTAL)
USERID_LPORTAL=21695
FOLDERID_LPORTAL=21742
STRUCTID_LPORTAL=21747
ROLENAME_LPORTAL=ChangelogAlert
PAGENAME_LPORTAL=changelog
MAILSUBJ_LPORTAL=STI Aggiornamento

portal-properties:
	$(call set_prop,/opt/tomcat/sti-dev.properties,sti\.group\.id,$(GROUPID_LPORTAL))
	$(call set_prop,/opt/tomcat/sti-dev.properties,sti\.changelog\.user\.id,$(USERID_LPORTAL))
	$(call set_prop,/opt/tomcat/sti-dev.properties,sti\.changelog\.folder\.id,$(FOLDERID_LPORTAL))
	$(call set_prop,/opt/tomcat/sti-dev.properties,sti\.changelog\.structure\.id,$(STRUCTID_LPORTAL))
	$(call set_prop,/opt/tomcat/sti-dev.properties,sti\.changelog\.role\.alert\.name,$(ROLENAME_LPORTAL))
	$(call set_prop,/opt/tomcat/sti-dev.properties,sti\.changelog\.page\.name,$(PAGENAME_LPORTAL))
	$(call set_prop,/opt/tomcat/sti-dev.properties,sti\.changelog\.email\.subject,$(MAILSUBJ_LPORTAL))

sti-env:
	sudo cp ./sti-cts2-portlets-build/extra/config/sti-dev.properties /opt/tomcat/ || echo "sti-dev already exists in HOME directory of tomcat"
	-sudo chown tomcat: /opt/tomcat/sti-dev.properties
	su tomcat -c 'echo "export STI_CTS2_CONFIG=\"/opt/tomcat/sti-dev.properties\"" >>/opt/tomcat/.bash_profile'
	su tomcat -c 'mkdir ~/stiIO/ 2>/dev/null || (echo "stiIO/ exists already. Deleting and recreating" && rm -r ~/stiIO/ && mkdir ~/stiIO/)'
	su tomcat -c 'mkdir ~/stiIO/import'
	su tomcat -c 'mkdir ~/stiIO/export'
	$(call set_prop,/opt/tomcat/sti-dev.properties,filesystem\.import\.base\.path,\/opt\/tomcat\/stiIO\/import)
	$(call set_prop,/opt/tomcat/sti-dev.properties,filesystem\.export\.base\.path,\/opt\/tomcat\/stiIO\/export)


test-prop-set:
	$(call set_prop,/opt/tomcat/sti-dev.properties,db\.sti\.username,foo)

install-node:
	curl -sL https://rpm.nodesource.com/setup_14.x | sudo bash -
	sudo yum install -y nodejs

######## Macros ##########

# Procedure download_lib
# Parameters :
# $(1) -> Filename
# $(2) -> URL
define download_lib
	if [ -f "/tmp/$(1)" ]; then echo "$(1) already downloaded"; else wget $(2) -P /tmp; fi
endef

# Procedure set_prop
# Parameters :
# $(1) -> Filename of properties file
# $(2) -> Key to search
# $(3) -> value to set
#
# Note : Is important to escape special chars in parameters.
# 		Example: component.property.to.change -> component\.property\.to\.change
#		[Same for everything could conflict with regex like *+.][}{ etc. ]
define set_prop
	sudo sed -i -Ee 's;^$(2)=.*$$;$(2)=$(3);g' $(1)
endef

# <import com.liferay> si trova in 
# sti-cts2-portlets-build : it.linksmt.cts2.portlet.search.rest : ManageCodeSystemController.java
# sti-cts2-portlets-build : it.linksmt.cts2.portlet.search.util : ChangelogUtils.java