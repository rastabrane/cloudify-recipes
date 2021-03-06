#! /bin/bash -x

bucket="yoram-biginsights"
HTTP_REPO=http://s3.amazonaws.com/BigInsights/
BIGINSIGHTS_VERSION=$3
#BIGINSIGHTS_VERSION="BASIC14"
echo "BIGINSIGHTS edition " $BIGINSIGHTS_VERSION
#folder="biginsights_basic/$ATTACHMENT_VERSION"
if [ -f "/tmp/bi_download.lock" ]
then
  echo "Not first boot - skipping attachment download"
else
	if [ $BIGINSIGHTS_VERSION = 'ENTERPRISE' ]
	then
		wget -nv ${HTTP_REPO}BIGINSIGHT_ENTPR_ED_V2.0_LNX.tar.gz
		tar --index-file /tmp/biginsights.tar.log -xvvf BIGINSIGHT_ENTPR_ED_V2.0_LNX.tar.gz -C /tmp/
		bidir=/tmp/biginsights-enterprise-linux64_*/
	else
		wget -nv https://s3.amazonaws.com/yoram-biginsights/iib14_linux_64.tar.gz
		tar --index-file /tmp/biginsights.tar.log -xvvf iib*_linux_64.tar.gz -C /tmp/
		bidir=/tmp/biginsights-basic*/
	fi

	bidir=`echo $bidir| sed s/.$//`
	export BIDIR=$bidir
echo '<?xml version="1.0" encoding="UTF-8"?>
<module xmlns="http://geronimo.apache.org/xml/ns/deployment-1.2">
<environment>
<moduleId>
<groupId>console.realm</groupId>
<artifactId>BigInsightsSecurityRealm</artifactId>
<version>1.0</version>
<type>car</type>
</moduleId>
<dependencies>
<dependency>
<groupId>org.apache.geronimo.framework</groupId>
<artifactId>j2ee-security</artifactId>
<type>car</type>
</dependency>
<dependency>
<groupId>BigData</groupId>
<artifactId>Authentication</artifactId>
<version>1.0</version>
<type>jar</type>
</dependency>
</dependencies>
</environment>
<gbean
class="org.apache.geronimo.security.realm.GenericSecurityRealm"
name="BigInsightsSecurityRealm"
xmlns:dep="http://geronimo.apache.org/xml/ns/deployment-1.2"
xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="dep:gbeanType">
<attribute name="realmName">BigInsightsSecurityRealm</attribute>
<reference name="ServerInfo">
<name>ServerInfo</name>
</reference>
<xml-reference name="LoginModuleConfiguration">
<log:login-config xmlns:log="http://geronimo.apache.org/xml/ns/loginconfig-2.0">
<log:login-module control-flag="REQUIRED" wrap-principals="false">
<log:login-domain-name>BigInsightsSecurityRealm</log:login-domain-name>
<log:login-module-class>com.ibm.biginsights.security.pam.PAMAuthenticationModule</log:login-module-class>
</log:login-module>
</log:login-config>
</xml-reference>
</gbean>
</module>' > $bidir/SecurityRealmPlan.xml

  	touch /tmp/bi_download.lock
fi

#sed -i 's/^Defaults    requiretty/#Defaults    requiretty/g' /etc/sudoers

if [[ $EUID -ne 0 ]]; then		
	echo "Not root, need sudo"		
	sudo mkdir $2
	sudo mkdir /mnt/hadoop && sudo ln -s /mnt/hadoop $2/hadoop
	sudo mkdir /mnt/ibm && sudo mkdir $2/var && sudo ln -s /mnt/ibm $2/var/ibm

	ulimit -n 16384
	echo "root hard nofile 16384" | sudo tee -a /etc/security/limits.conf
	echo "root soft nofile 16384" | sudo tee -a /etc/security/limits.conf
	sudo sed -i 's/^Defaults.*requiretty/#&/g' /etc/sudoers
	sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
	sudo setenforce 0
	sudo groupadd biadmin
	sudo useradd -g biadmin -d /home/biadmin biadmin
	sudo echo biadmin:$1 | sudo chpasswd
	echo 'biadmin ALL=(ALL) NOPASSWD:ALL' | sudo tee -a /etc/sudoers
	sudo chown -R biadmin.biadmin $2
        sudo rpm -ihv ${BIDIR}/artifacts/expect-5.42.1-1.x86_64.rpm	
#	if ! type "yum" > /dev/null; then
# 		sudo apt-get -q -y install expect
# 	else
#		sudo yum -y -q install expect
#	fi	
	sudo groupadd bi-sysadmin
	sudo groupadd bi-dataadmin
	sudo groupadd bi-appadmin
	sudo groupadd bi-user
	
else
	mkdir $2
	mkdir /mnt/hadoop && ln -s /mnt/hadoop $2/hadoop
	mkdir /mnt/ibm && mkdir $2/var && ln -s /mnt/ibm $2/var/ibm

	ulimit -n 16384
	echo "root hard nofile 16384" >> /etc/security/limits.conf
	echo "root soft nofile 16384" >> /etc/security/limits.conf	groupadd biadmin
	sed -i 's/^Defaults.*requiretty/#&/g' /etc/sudoers
	sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
	setenforce 0
	groupadd biadmin
	useradd -g biadmin -d /home/biadmin biadmin
	echo biadmin:$1 | chpasswd
	echo 'biadmin ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
	chown -R biadmin.biadmin $2
        rpm -ihv ${BIDIR}/artifacts/expect-5.42.1-1.x86_64.rpm
#	if ! type "yum" > /dev/null; then
#		apt-get -y -q install expect
#	else
#		yum -y -q install expect
#	fi	
	groupadd bi-sysadmin
	groupadd bi-dataadmin
	groupadd bi-appadmin
	groupadd bi-user

fi


exit 0


