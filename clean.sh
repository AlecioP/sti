sudo rm /etc/systemd/system/tomcat.service
sudo rm /tmp/apache*
sudo rm /opt/tomcat/latest
sudo rm -r /opt/tomcat/apache-tomcat-9.0.65

read -n 1 -p "Proced to delete user tomcat?(y/n)" action
if [ "$action" = "y" ]; then
    sudo killall -u tomcat
    sudo userdel -r tomcat
fi