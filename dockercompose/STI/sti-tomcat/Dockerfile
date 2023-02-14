ARG image_v=8.7-20221201
FROM almalinux:${image_v}

ARG tomcat_v=9.0.68
ARG lportal_v=7.4.3.59-ga59
ARG lportal_archive=liferay-ce-portal-tomcat-7.4.3.59-ga59-20230112145006317.tar.gz 
ARG lportal_repo=https://github.com/liferay/liferay-portal/releases/download/${lportal_v}

ARG sti_v=v0.9-alpha-docker
ARG sti_repo=https://github.com/aleciop/sti/releases/download/${sti_v}



WORKDIR /root

RUN mkdir PID

ARG logo_path=liferay-ce-portal-${lportal_v}/data/document_library/0/0/43119.png
RUN mkdir -p ${logo_path}

# Don't know why github adds this .0 extension 
ADD ${sti_repo}/logo.png.0 ${logo_path}/1.0

ADD ${lportal_repo}/${lportal_archive} ./

RUN tar -xf ${lportal_archive}

ARG path_root_xml=liferay-ce-portal-${lportal_v}/tomcat-${tomcat_v}/conf/Catalina/localhost

RUN rm ${path_root_xml}/ROOT.xml

ADD ${sti_repo}/ROOT_wDB.xml ${path_root_xml}/ROOT.xml

RUN cd ${path_root_xml} && sed -i -E -e 's/172\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}/172\.20\.0\.3/g' ROOT.xml

ARG path_bin=liferay-ce-portal-${lportal_v}/tomcat-${tomcat_v}/bin

RUN rm ${path_bin}/setenv.sh

ADD ${sti_repo}/setenv.sh ${path_bin}/setenv.sh

ARG path_configs=liferay-ce-portal-${lportal_v}/osgi/configs

ARG config_name=com.liferay.portal.search.elasticsearch7.configuration.ElasticsearchConfiguration.config

ADD ${sti_repo}/${config_name} ${path_configs}/${config_name}

RUN cd ${path_configs} && sed -i -E -e 's/172\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}/172\.20\.0\.4/g' ${config_name}

ARG portal_ext=portal-ext.properties

ADD ${sti_repo}/${portal_ext} liferay-ce-portal-${lportal_v}

RUN cd liferay-ce-portal-${lportal_v} && sed -i -E -e 's/172\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}/172\.20\.0\.3/g' ${portal_ext}

# The following is probably not so portable since the jdk archive is specific for cpu architecture
# Therefore if the archive is not compatible with your architecture, you can change the following
# 3 parameters in order to fetch it from somewhere else at build time
#
# If doing so, remember to change JAVA_HOME in setenv.sh script
#
# USAGE :
#
# --build-arg jdk_repo=https://your-repo.org
# --build-arg jdk_rpm=jdk-<version>-<architecture>
#
# REPLACE THIS
#
#ARG jdk_repo=${sti_repo}
#ARG jdk_rpm=jdk-8u341-linux-x64.rpm
#ARG jdk_dir=jdk1.8.0_341-amd64
#
#ADD ${jdk_repo}/${jdk_rpm} ./
#
#RUN rpm -Uvh localinstall /root/${jdk_rpm}
#
#RUN alternatives --set java /usr/java/${jdk_dir}/bin/java
#
# WITH THIS
RUN yum -y install java-1.8.0-openjdk-devel && yum -y install epel-release && yum -y install htop
