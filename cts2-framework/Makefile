# Get directory containing this makefile
MKF_ABS := $(abspath $(lastword $(MAKEFILE_LIST)))
THIS_DIR := $(dir $(MKF_ABS))

JAVA_HOME = /usr/lib/jvm/jre
JAVA_OPTS = -Djava.security.egd=file:///dev/urandom

CATALINA_BASE = /opt/tomcat/apache-tomcat-9.0.65
CATALINA_HOME = /opt/tomcat/apache-tomcat-9.0.65
CATALINA_PID = /opt/tomcat/apache-tomcat-9.0.65/temp/tomcat.pid
CATALINA_OPTS = -Xms512M -Xmx1024M -server -XX:+UseParallelGC -Djava.security.manager -Djava.security.policy=$(CATALINA_BASE)/conf/catalina.policy

TOMCAT_V = 9.0.65

# Procedure download_lib
# Parameters :
# $(1) -> Filename
# $(2) -> URL
define download_lib
	if [ -f "/tmp/$(1)" ]; then echo "$(1) already downloaded"; else wget $(2) -P /tmp; fi
endef

clean: clean-liferay-build clean-liferay clean-tomcat

clean-no-tmp: clean-liferay-build clean-tomcat



all: prerequisites clean-tomcat tomcat clean-liferay liferay
	echo "done!"
install-prerequisites:
	sudo yum install make

	sudo yum install git

# If you haven't installed java already, actually
# the install of apache-maven alone will also trigger
# the right version of java (on which mvn depends)
# to be installed. No real need to use command below

	sudo yum install java-11-openjdk java-11-openjdk-devel

	sudo yum install apache-maven

prerequisites:

	echo "Prerequisites : "
	echo " "

	make --version
	echo " "
	git --version
	echo " "
	java -version
	echo " "
	mvn -version
	echo " "

print-info: prerequisites show-deps

	echo "Local repository clone in $(THIS_DIR)"
	echo " "

	echo "STI-CTS2-FRAMEWORK Build file"
	echo "What are the steps ?"
	echo "1) Install Tomcat Application server (Tomcat hosts applications -> Liferay)"
	echo "2) Install Liferay Portal (Liferay hosts servlets -> CTS2)"
	echo "3) Install CTS2-Framework (CTS2-Framework hosts services -> STI-Service)"
	echo "4) Install STI-Service"
	echo "5) Install STI-Portlets (to actually access STI-Service [maybe?])"

show-deps:
	echo "Dependencies links: "
	echo " "
	cat Makefile | grep -E 'download_lib' | grep -v Makefile | sed -Ee 's/(\t|\s)*wget\s\"?(https[^\"]*)\"?/\2/g' 
	echo " "

tomcat:

# Step 1 : Install Tomcat 9

# Reference : https://linuxize.com/post/how-to-install-tomcat-9-on-centos-7/

# -M : NO HOME DIRECTORY FOR USER
# -m : CREATE HOME DIRECTORY FOR USER
# -d : USE SPECIFIC DIRECTORY AS HOME
# -U : CREATE NEW GROUP WITH SAME NAME OF USER (TOMCAT GROUP)
# -s : DEFAULT USER SHELL

# Create a user that will run tomcat service

	read -n 1 -p "Skip useradd ? (y/n)" action &&\
	echo " " &&\
	if [ "$${action}" != "y" ]; then sudo useradd -M -U -s /bin/false tomcat && sudo -u tomcat mkdir /opt/tomcat; fi

# Download
	$(call download_lib,apache-tomcat-$(TOMCAT_V).tar.gz,"https://dlcdn.apache.org/tomcat/tomcat-9/v$(TOMCAT_V)/bin/apache-tomcat-$(TOMCAT_V).tar.gz")
# Extract
	sudo tar -xf "/tmp/apache-tomcat-$(TOMCAT_V).tar.gz" -C /tmp
# Move sources
	sudo cp -r "/tmp/apache-tomcat-$(TOMCAT_V)" /opt/tomcat/

# Make version update easier
# (Generate simblink to refer to latest version, currently pointing to v9)
	sudo ln -s "/opt/tomcat/apache-tomcat-$(TOMCAT_V)" /opt/tomcat/latest

# Let's make sure user above has access to dir containing sources

	sudo chown -R tomcat: /opt/tomcat

# Also make sure can run tomcat's scripts

	sudo sh -c 'chmod +rx /opt/tomcat/latest/bin/*.sh'

	sudo sh -c 'chmod a+rwx /opt /opt/tomcat/ /opt/tomcat/latest /opt/tomcat/latest/bin'

# AlmaLinux enables SELinux which prevents systemctl to run binaries tagged user_tmp_t but only allows bin_t type
# Reference : https://bugs.almalinux.org/view.php?id=212

	sudo chcon --type=bin_t /opt/tomcat/latest/bin/startup.sh
	sudo chcon --type=bin_t /opt/tomcat/latest/bin/shutdown.sh

# Create a service manageable from sysctl

	sudo bash -c "cat  $(THIS_DIR)/conf/tomcat-service >/etc/systemd/system/tomcat.service"

# Add to sysctl
	sudo systemctl daemon-reload

# Enable service 
	systemctl enable tomcat

# Just fine with https://linuxize.com/post/how-to-install-tomcat-9-on-centos-7/ tutorial

clean-tomcat:
	- sudo rm /etc/systemd/system/tomcat.service
	- sudo rm /tmp/apache*
	- sudo rm /opt/tomcat/latest
	- sudo rm -r /opt/tomcat/apache-tomcat-9.0.65

# &&\ at end of nextline is very important, allows to maintain var action w/o 
# create new shell instance for following if statement. DO NOT DELETE

	read -n 1 -p "Proceed to delete user tomcat?(y/n)" action &&\
	echo " " &&\
	if [ "$${action}" = "y" ]; then \
		sudo killall -u tomcat \
		sudo userdel -r tomcat \
		sudo rmdir /opt/tomcat; \
	fi


clean-liferay:
	sudo rm -rf /opt/tomcat/apache-tomcat-9.0.65/lib/ext/
	read -n 1 -p "Ctrl+c to abort. Press any key to proceed deleting all liferay libs downloaded in /tmp " action
	echo " "
	sudo rm /tmp/liferay*
	sudo rm /tmp/support-tomcat*
	sudo rm /tmp/jta*
	sudo rm /tmp/javax.mail*
	sudo rm /tmp/persistence*

LIFERAY_WAR =liferay-portal-6.2-ce-ga6-20160112152609836.war
LIFERAY_DEP =liferay-portal-dependencies-6.2-ce-ga6-20160112152609836.zip

SUPPORT_JAR =support-tomcat-6.2.1.jar
JTA_JAR =jta-1.1.jar
JAVAMAIL_JAR =javax.mail-1.6.2.jar
PERSISTENCE_JAR =persistence-api-1.0.2.jar
JDBC_JAR =postgresql-42.5.0.jar
JAF_JAR =activation-1.1.1.jar

liferay-deps-download:
# Liferay libs from https://sourceforge.net/projects/lportal/files/Liferay%20Portal/6.2.5%20GA6/
# Reference : https://help.liferay.com/hc/en-us/articles/360017903112-Installing-Liferay-on-Tomcat-7
	
	$(call download_lib,$(LIFERAY_WAR),"https://master.dl.sourceforge.net/project/lportal/Liferay%20Portal/6.2.5%20GA6/$(LIFERAY_WAR)")
	
	$(call download_lib,$(LIFERAY_DEP),"https://master.dl.sourceforge.net/project/lportal/Liferay%20Portal/6.2.5%20GA6/$(LIFERAY_DEP)")
	
	if [ ! -f "$(CATALINA_HOME)/lib/ext" ]; then sudo -u tomcat mkdir  $(CATALINA_HOME)/lib/ext; fi
	
# Since Liferay dependencies zip contains only jars but has no directory structure, we can use unzip -j
# -j : Just extract do not preserve archive directory structure

	sudo -u tomcat unzip -j /tmp/$(LIFERAY_DEP) -d $(CATALINA_HOME)/lib/ext

	$(call download_lib,$(SUPPORT_JAR),"https://repo1.maven.org/maven2/com/liferay/portal/support-tomcat/6.2.1/$(SUPPORT_JAR)")
	sudo -u tomcat cp /tmp/$(SUPPORT_JAR) $(CATALINA_HOME)/lib/ext
	
	$(call download_lib,$(JTA_JAR),"https://repo1.maven.org/maven2/javax/transaction/jta/1.1/$(JTA_JAR)")
	sudo -u tomcat cp /tmp/$(JTA_JAR) $(CATALINA_HOME)/lib/ext
	
	$(call download_lib,$(JAVAMAIL_JAR),"https://maven.java.net/content/repositories/releases/com/sun/mail/javax.mail/1.6.2/$(JAVAMAIL_JAR)")
	sudo -u tomcat cp /tmp/$(JAVAMAIL_JAR) $(CATALINA_HOME)/lib/ext
	
	$(call download_lib,$(PERSISTENCE_JAR),"https://repo1.maven.org/maven2/javax/persistence/persistence-api/1.0.2/$(PERSISTENCE_JAR)")
	sudo -u tomcat cp /tmp/$(PERSISTENCE_JAR) $(CATALINA_HOME)/lib/ext
	
	$(call download_lib,$(JDBC_JAR),"https://repo1.maven.org/maven2/org/postgresql/postgresql/42.5.0/$(JDBC_JAR)")
	sudo -u tomcat cp /tmp/$(JDBC_JAR) $(CATALINA_HOME)/lib/ext
# Skipping download of optional jars (assuming they're optional)

	$(call download_lib,$(JAF_JAR),"https://repo1.maven.org/maven2/javax/activation/activation/1.1.1/$(JAF_JAR)")
	sudo -u tomcat cp /tmp/$(JAF_JAR) $(CATALINA_HOME)/lib/ext
	
clean-liferay-build:
	sudo rm -r $(CATALINA_HOME)/conf/Catalina/localhost/
	sudo rm $(CATALINA_HOME)/conf/catalina.properties
	sudo cp $(THIS_DIR)conf/copy-catalina-properties $(CATALINA_HOME)/conf/catalina.properties
	sudo rm $(CATALINA_HOME)/conf/server.xml
	sudo cp $(THIS_DIR)conf/copy-server.xml $(CATALINA_HOME)/conf/server.xml
	sudo rm $(CATALINA_HOME)/conf/catalina.policy
	sudo cp $(THIS_DIR)conf/copy-catalina-policy $(CATALINA_HOME)/conf/catalina.policy

liferay-build: #clean-liferay-build

# Security issues with examples webapp. Just deleting it

	- sudo rm -r $(CATALINA_HOME)/webapps/examples

# -p : Create every intermediate directory if not exists
	- sudo -u tomcat mkdir -p $(CATALINA_HOME)/conf/Catalina/localhost

	sudo sh -c "cat $(THIS_DIR)conf/ROOT.xml >$(CATALINA_HOME)/conf/Catalina/localhost/ROOT.xml"

	sudo cp $(CATALINA_HOME)/conf/catalina.properties $(THIS_DIR)conf/copy-catalina-properties

	sudo sed -i -Ee 's/(common\.loader.*)$$/\1,"\$${catalina\.home}\/lib\/ext","\$${catalina\.home}\/lib\/ext\/\*\.jar"/g' $(CATALINA_HOME)/conf/catalina.properties

	sudo cp $(CATALINA_HOME)/conf/server.xml $(THIS_DIR)conf/copy-server.xml
	
	sudo sed -i -Ee 's/(redirectPort="8443")/\1 URIEncoding="UTF-8"/g' $(CATALINA_HOME)/conf/server.xml

	- sudo -u tomcat rm $(CATALINA_HOME)/webapps/support-catalina*.jar

	sudo cp $(CATALINA_HOME)/conf/catalina.policy $(THIS_DIR)conf/copy-catalina-policy

	if test -z $(sudo cat $(CATALINA_HOME)/conf/catalina.policy | grep grant*AllPermission); then sudo sh -c "printf '\ngrant {permission java.security.AllPermission;};' >> $(CATALINA_HOME)/conf/catalina.policy"; fi

	- sudo rm -r $(CATALINA_HOME)/webapps/ROOT/
	sudo -u tomcat sh -c "mkdir $(CATALINA_HOME)/webapps/ROOT/"

	sudo -u tomcat sh -c "unzip /tmp/$(LIFERAY_WAR) -d $(CATALINA_HOME)/webapps/ROOT"

liferay: liferay-deps-download liferay-build

run: 
	systemctl start tomcat
#	firefox -new-tab "localhost:8080"
stop:
	systemctl stop tomcat

status:
	systemctl status tomcat

logs:
#	- rm $(THIS_DIR)output* 
	for f in $$(sudo ls $(LIFERAY_HOME)/logs); do sudo cp $(LIFERAY_HOME)/logs/$$f $(THIS_DIR)output-$$f ; done
#	for f in $$(sudo ls $(LIFERAY_HOME)/logs); do sudo echo $$f ; done
	sudo cp $(CATALINA_HOME)/logs/catalina.out $(THIS_DIR)output-catalina.log
	sudo chown $${USER}: $(THIS_DIR)output* 
catalina-log:
	if test -z $(THIS_DIR)output; then rm $(THIS_DIR)output; fi
	sudo cat /opt/tomcat/apache-tomcat-9.0.65/logs/catalina.out >./output
clean-catalina-log:
	sudo rm /opt/tomcat/apache-tomcat-9.0.65/logs/catalina.out

LIFERAY_HOME= $(CATALINA_HOME)/..

update-pom:
	mvn versions:use-latest-releases

clean-cts2-plugin:
	- sudo rm $(CATALINA_HOME)/webapps/cts2-webapp.war
	- sudo rm -r $(CATALINA_HOME)/webapps/cts2-webapp
	sudo ls -l $(CATALINA_HOME)/webapps/
cts2-plugin:
	@echo "Potential dependencies updates :"
	@echo " "
#	mvn versions:display-dependency-updates | grep -e "\->"
	@echo " "
	@echo "Consider updating using target update-pom (make update-pom)"
	@echo "Building artifact"
	@echo " "
#	mvn clean install -DskipTests=true | grep -v "Downloading from" | grep -v "Downloaded from"

#	read -n 1 -p "Ctrl+c to stop, anything else to continue"
	@echo " "

	
	sudo cp $(THIS_DIR)cts2-webapp/target/cts2-webapp-1.2.0.FINAL.war $(CATALINA_HOME)/webapps/cts2-webapp.war
	sudo chown tomcat: $(CATALINA_HOME)/webapps/cts2-webapp.war
