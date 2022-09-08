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

##################################################################################################################

echo "Step 1 : Tomcat installation. Action required! 1 : continue - 2 : skip - 3(or else) : abort"
read -n 1 -p "Action:" action

if [ "$action" = "1" ]; then

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
    wget https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.65/bin/apache-tomcat-9.0.65.tar.gz
    # Extract
    tar -xf apache-tomcat-9.0.65.tar.gz
    # Move sources
    sudo mv apache-tomcat-9.0.65 /opt/tomcat/

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
    Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC -Djava.security.manager -Djava.security.policy=$CATALINA_BASE/conf/catalina.policy"
    

    ExecStart=/opt/tomcat/latest/bin/startup.sh --security
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
else
    if [ "$action" != "2" ]; then
        echo "Aborting..."
    fi
fi

##################################################################################################################

echo "Step 2 : Liferay installation. Action required! 1 : continue - 2 : skip - 3(or else) : abort"
read -n 1 -p "Action:" action

if [ "$action" = "1" ]; then

    # Step 2 : Install Liferay
    # Liferay libs from https://sourceforge.net/projects/lportal/files/Liferay%20Portal/6.2.5%20GA6/
    # Reference : https://help.liferay.com/hc/en-us/articles/360017903112-Installing-Liferay-on-Tomcat-7

    LIFERAY_WAR="liferay-portal-6.2-ce-ga6-20160112152609836.war"
    LIFERAY_DEP="liferay-portal-dependencies-6.2-ce-ga6-20160112152609836.zip"

    cd /tmp

    wget https://master.dl.sourceforge.net/project/lportal/Liferay%20Portal/6.2.5%20GA6/liferay-portal-6.2-ce-ga6-20160112152609836.war
    wget https://master.dl.sourceforge.net/project/lportal/Liferay%20Portal/6.2.5%20GA6/liferay-portal-dependencies-6.2-ce-ga6-20160112152609836.zip

    mkdir $CATALINA_HOME/lib/ext
    unzip $LIFERAY_DEP -d $CATALINA_HOME/lib/ext

    SUPPORT_JAR="support-tomcat-6.2.1.jar"

    wget https://repo1.maven.org/maven2/com/liferay/portal/support-tomcat/6.2.1/support-tomcat-6.2.1.jar

    mv $SUPPORT_JAR $CATALINA_HOME/lib/ext

    JTA_JAR="jta-1.1.jar"

    wget https://repo1.maven.org/maven2/javax/transaction/jta/1.1/jta-1.1.jar

    mv $JTA_JAR $CATALINA_HOME/lib/ext

    JAVAMAIL_JAR="javax.mail-1.6.2.jar"

    wget https://maven.java.net/content/repositories/releases/com/sun/mail/javax.mail/1.6.2/javax.mail-1.6.2.jar

    mv $JAVAMAIL_JAR $CATALINA_HOME/lib/ext

    PERSISTENCE_JAR="persistence-api-1.0.2.jar"

    wget https://repo1.maven.org/maven2/javax/persistence/persistence-api/1.0.2/persistence-api-1.0.2.jar

    mv $PERSISTENCE_JAR $CATALINA_HOME/lib/ext

    JDBC_JAR="postgresql-42.5.0.jar"

    wget https://repo1.maven.org/maven2/org/postgresql/postgresql/42.5.0/postgresql-42.5.0.jar

    mv $JDBC_JAR $CATALINA_HOME/lib/ext

    # Skipping download of optional jars (assuming they're optional)

    CATALINA_OPTS="$CATALINA_OPTS -Dfile.encoding=UTF-8 -Dorg.apache.catalina.loader.WebappClassLoader.ENABLE_CLEAR_REFERENCES=false -Duser.timezone=GMT -XX:MaxPermSize=256m"

    # -p : Create every intermediate directory if not exists
    mkdir -p $CATALINA_HOME/conf/Catalina/localhost

    echo "<Context path=\"\" crossContext=\"true\">

     <!-- JAAS -->

     <!--<Realm
         classNjame=\"org.apache.catalina.realm.JAASRealm\"
         appName=\"PortalRealm\"
         userClassNames=\"com.liferay.portal.kernel.security.jaas.PortalPrincipal\"
         roleClassNames=\"com.liferay.portal.kernel.security.jaas.PortalRole\"
     />-->

     <!--
     Uncomment the following to disable persistent sessions across reboots.
     -->

     <!--<Manager pathname=\"\" />-->

     <!--
     Uncomment the following to not use sessions. See the property
     \"session.disabled\" in portal.properties.
     -->

     <!--<Manager className=\"com.liferay.support.tomcat.session.SessionLessManagerBase\" />-->
    </Context>" >$CATALINA_HOME/conf/Catalina/localhost/ROOT.xml

    sed -Ee -i$CATALINA_HOME/conf/catalina.properties 's/(common\.loader.*)$/\1,\${catalina\.home}\/lib\/ext,\${catalina\.home}\/lib\/ext\/\*\.jar/g'

    sed -Ee -i$CATALINA_HOME/conf/server.xml 's/(redirectPort=\"8443\")/\1 URIEncoding=\"UTF-8\"/g'

    if test -f "$CATALINA_HOME/webapps/support-catalina*.jar"; then
        rm $CATALINA_HOME/webapps/support-catalina*.jar
    fi

    if test -f "$CATALINA_HOME/conf/catalina.policy"; then
        if test -z $(cat $CATALINA_HOME/conf/catalina.policy | grep grant); then
            echo "grant {permission java.security.AllPermission;};" >> $CATALINA_HOME/conf/catalina.policy
        fi
    fi

    sudo systemctl stop tomcat

    sudo rm $CATALINA_HOME/webapps/ROOT/*

    unzip $LIFERAY_WAR -d $CATALINA_HOME/webapps/ROOT 

    sudo systemctl reload tomcat

    sudo systemctl start tomcat

else
    if [ "$action" != "2" ]; then
        echo "Aborting..."
    fi
fi

##################################################################################################################
echo "Step 3 : CTS2 maven build and installation. Action required! 1 : continue - 2 : skip - 3(or else) : abort"
if [ "$action" = "1" ]; then
    mvn clean install
else
    if [ "$action" != "2" ]; then
        echo "Aborting..."
    fi
fi