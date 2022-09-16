# Get directory containing this makefile
MKF_ABS := $(abspath $(lastword $(MAKEFILE_LIST)))
THIS_DIR := $(dir $(MKF_ABS))

JAVA_HOME = /usr/lib/jvm/jre
JAVA_OPTS = -Djava.security.egd=file:///dev/urandom

CATALINA_BASE = /opt/tomcat/apache-tomcat-9.0.65
CATALINA_HOME = /opt/tomcat/apache-tomcat-9.0.65
CATALINA_PID = /opt/tomcat/apache-tomcat-9.0.65/temp/tomcat.pid
CATALINA_OPTS = -Xms512M -Xmx1024M -server -XX:+UseParallelGC -Djava.security.manager -Djava.security.policy=$CATALINA_BASE/conf/catalina.policy

# Procedure download_lib
# Parameters :
# $(1) -> Filename
# $(2) -> URL
define download_lib
	if [ -f "/tmp/$(1)" ]; then echo "$(1) already downloaded"; else wget $(2) -P /tmp; fi
endef

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

TOMCAT_V = 9.0.65

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
	sudo systemctl enable tomcat
# Start service
	sudo systemctl start tomcat
# Check service
	sudo systemctl status tomcat
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
	read -n 1 -p "Time to ctrl+c my guy" action
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


liferay-deps-download:
# Liferay libs from https://sourceforge.net/projects/lportal/files/Liferay%20Portal/6.2.5%20GA6/
# Reference : https://help.liferay.com/hc/en-us/articles/360017903112-Installing-Liferay-on-Tomcat-7
	
	$(call download_lib,$(LIFERAY_WAR),"https://master.dl.sourceforge.net/project/lportal/Liferay%20Portal/6.2.5%20GA6/$(LIFERAY_WAR)")
	
	$(call download_lib,$(LIFERAY_DEP),"https://master.dl.sourceforge.net/project/lportal/Liferay%20Portal/6.2.5%20GA6/$(LIFERAY_DEP)")
	
	if [ ! -f "$(CATALINA_HOME)/lib/ext" ]; then sudo -u tomcat mkdir  $(CATALINA_HOME)/lib/ext; fi
	
	sudo -u tomcat unzip /tmp/$(LIFERAY_DEP) -d $(CATALINA_HOME)/lib/ext

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

liferay-build:
	
	CATALINA_OPTS="$(CATALINA_OPTS) -Dfile.encoding=UTF-8 -Dorg.apache.catalina.loader.WebappClassLoader.ENABLE_CLEAR_REFERENCES=false -Duser.timezone=GMT -XX:MaxPermSize=256m"

# -p : Create every intermediate directory if not exists
	sudo -u tomcat mkdir -p $(CATALINA_HOME)/conf/Catalina/localhost

	cat $(THIS_DIR)/conf/ROOT.xml >$(CATALINA_HOME)/conf/Catalina/localhost/ROOT.xml

	sed -Ee -i$(CATALINA_HOME)/conf/catalina.properties 's/(common\.loader.*)$/\1,\${catalina\.home}\/lib\/ext,\${catalina\.home}\/lib\/ext\/\*\.jar/g'

	read -n 1 -p "Time to ctrl+c and check ./conf/catalina-properties" action

	sed -Ee -i$(CATALINA_HOME)/conf/server.xml 's/(redirectPort=\"8443\")/\1 URIEncoding=\"UTF-8\"/g'

	if test -f "$(CATALINA_HOME)/webapps/support-catalina*.jar"; then rm $(CATALINA_HOME)/webapps/support-catalina*.jar; fi

	if test -f "$(CATALINA_HOME)/conf/catalina.policy"; then if test -z $(cat $(CATALINA_HOME)/conf/catalina.policy | grep grant); then echo "grant {permission java.security.AllPermission;};" >> $(CATALINA_HOME)/conf/catalina.policy; fi; fi

	sudo systemctl stop tomcat

	sudo rm $(CATALINA_HOME)/webapps/ROOT/*

	sudo -u tomcat unzip $(LIFERAY_WAR) -d $(CATALINA_HOME)/webapps/ROOT 

	sudo systemctl reload tomcat

	sudo systemctl start tomcat

liferay: liferay-deps-download liferay-build
