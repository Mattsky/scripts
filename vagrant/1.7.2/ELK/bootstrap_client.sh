        echo Installing.
        date > /etc/systembuild
        echo '172.28.128.100    puppet puppet-server puppet-server.localdomain' >> /etc/hosts
        rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-el-6.noarch.rpm
        yum clean all
        yum -y install puppet
        sed -i -e 's/=permissive/=disabled/' /etc/selinux/config

	# Logstash forwarder provisioning

	# Grab cert for secure forwarding

	chmod 600 ~/.ssh/vagrant
	ssh-keyscan 172.28.128.100 >> ~/.ssh/known_hosts
	scp -i ~/.ssh/vagrant vagrant@172.28.128.100:/etc/pki/tls/certs/logstash-forwarder.crt /tmp

	# Install forwarder package

	cd ~
	curl -O http://download.elasticsearch.org/logstash-forwarder/packages/logstash-forwarder-0.3.1-1.x86_64.rpm
	rpm -ivh ~/logstash-forwarder-0.3.1-1.x86_64.rpm

	# Install init script

	cd /etc/init.d
	curl -o logstash-forwarder http://logstashbook.com/code/4/logstash_forwarder_redhat_init
	chmod +x logstash-forwarder

	# Install sysconfig file for dependency

	curl -o /etc/sysconfig/logstash-forwarder http://logstashbook.com/code/4/logstash_forwarder_redhat_sysconfig

	# Tweak settings

	sed -i -e 's/LOGSTASH_FORWARDER.*/LOGSTASH_FORWARDER_OPTIONS\=\"\-config\ \/etc\/logstash\-forwarder\ \-spool\-size\ 100\"/' /etc/sysconfig/logstash-forwarder

	cp /tmp/logstash-forwarder.crt /etc/pki/tls/certs	

	chkconfig --add logstash-forwarder
	chkconfig logstash-forwarder on
        chkconfig puppet on

	reboot
