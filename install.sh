#!/bin/sh

#sudo yum install git

git --version

# If you haven't installed java already, actually
# the install of apache-maven alone will also trigger
# the right version of java (on which mvn depends)
# to be installed. No real need to use command below

#sudo yum install java-11-openjdk java-11-openjdk-devel

java -version

#sudo yum install apache-maven

mvn -version

#STI-CTS2-FRAMEWORK Build

# What are the steps ? 

# 1) Install Tomcat Application server (Tomcat hosts applications -> Liferay)

# 2) Install Liferay Portal (Liferay hosts servlets -> CTS2)

# 3) Install CTS2-Framework (CTS2-Framework hosts services -> STI-Service)

# 4) Install STI-Service

# 5) Install STI-Portlets (to actually access STI-Service [maybe?])

# Step 1 : Install Tomcat 9

# Reference : https://linuxize.com/post/how-to-install-tomcat-9-on-centos-7/

# -m : CREATE HOME DIRECTORY FOR USER
# -d : USE SPECIFIC DIRECTORY AS HOME
# -U : CREATE NEW GROUP WITH SAME NAME OF USER (TOMCAT GROUP)
# -s : DEFAULT USER SHELL

# Create a user that will run tomcat service

sudo useradd -m -U -d /opt/tomcat -s /bin/false tomcat

cd /tmp
# Download
wget https://www-eu.apache.org/dist/tomcat/tomcat-9/v9.0.27/bin/apache-tomcat-9.0.27.tar.gz
# Extract
tar -xf apache-tomcat-9.0.27.tar.gz
# Move sources
sudo mv apache-tomcat-9.0.27 /opt/tomcat/

# Make version update easier
# (Generate simblink to refer to latest version, currently pointing to v9)
sudo ln -s /opt/tomcat/apache-tomcat-9.0.27 /opt/tomcat/latest

# Let's make sure user above has access to dir containing sources

sudo chown -R tomcat: /opt/tomcat

# Also make sure can run tomcat's scripts

sudo sh -c 'chmod +x /opt/tomcat/latest/bin/*.sh'

# Create a service manageable from sysctl

sudo echo "[Unit]
Description=Tomcat 9 servlet container
After=network.target

[Service]
Type=forking

User=tomcat
Group=tomcat

Environment="JAVA_HOME=/usr/lib/jvm/jre"
Environment="JAVA_OPTS=-Djava.security.egd=file:///dev/urandom"

Environment="CATALINA_BASE=/opt/tomcat/latest"
Environment="CATALINA_HOME=/opt/tomcat/latest"
Environment="CATALINA_PID=/opt/tomcat/latest/temp/tomcat.pid"
Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"

ExecStart=/opt/tomcat/latest/bin/startup.sh
ExecStop=/opt/tomcat/latest/bin/shutdown.sh

[Install]
WantedBy=multi-user.target
" >/etc/systemd/system/tomcat.service

# Add to sysctl
sudo systemctl daemon-reload

# Enable service 
sudo systemctl enable tomcat
# Start service
sudo systemctl start tomcat
# Check service
sudo systemctl status tomcat

# Just fine with https://linuxize.com/post/how-to-install-tomcat-9-on-centos-7/ tutorial

# Step 2 : Install Liferay

