        echo Installing.
        date > /etc/systembuild
        
	# Install and configure puppet server

	rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-el-6.noarch.rpm
        yum clean all
        yum -y install puppet-server sleep
        sed -i -e '/vardir\/ssl/a dns_alt_names = puppet,puppet-server,puppet-server.localdomain' /etc/puppet/puppet.conf
        puppet master --verbose --no-daemonize &
        sleep 30
        sed -i -e 's/=permissive/=disabled/' /etc/selinux/config
        chkconfig puppetmaster on
        
	# Java & elasticsearch install

	yum -y install java-1.7.0-openjdk
	rpm --import http://packages.elasticsearch.org/GPG-KEY-elasticsearch
	yum -y install elasticsearch
	
	grep "script.disable_dynamic" /etc/elasticsearch/elasticsearch.yml
	if [ $? -ne 0 ]; then
		echo "script.disable_dynamic: true" >> /etc/elasticsearch/elasticsearch.yml
	fi
	
	sed -i -e 's/\#\ network\.host.*/network\.host\:\ 127\.0\.0\.1/' /etc/elasticsearch/elasticsearch.yml

	sed -i -e 's/\#\ discovery\.zen\.ping\.multicast\.enabled.*/discovery\.zen\.ping\.multicast\.enabled\:\ true/' /etc/elasticsearch/elasticsearch.yml

	# Kibana install

	cd ~
	curl -O https://download.elasticsearch.org/kibana/kibana/kibana-3.0.1.tar.gz
	tar xvf ~/kibana-3.0.1.tar.gz

	# Configure Kibana port and prepare nginx content directory

	sed -i -e 's/elasticsearch\:\ \".*/elasticsearch:\ \"http\:\/\/localhost\:8080\",/' ~/kibana-3.0.1/config.js	
	mkdir -p /usr/share/nginx/kibana3; cp -R ~/kibana-3.0.1/* /usr/share/nginx/kibana3/

	# Install nginx and configure request forwarding

	yum -y install epel-release	
	yum -y install nginx
	cd ~
	curl -OL https://gist.githubusercontent.com/thisismitch/2205786838a6a5d61f55/raw/f91e06198a7c455925f6e3099e3ea7c186d0b263/nginx.conf

	# Change listening port to match port forwarding rules on VBox 
	sed -i -e 's/listen.*/listen		8080\ \;/' nginx.conf
	sed -i -e 's/server_name.*/server_name		localhost\;/' nginx.conf
	sed -i -e 's/root.*/root\ \ \/usr\/share\/nginx\/kibana3\;/' nginx.conf

	cp -f ~/nginx.conf /etc/nginx/conf.d/default.conf

	# Install logstash

	yum -y install logstash-1.4.2

	# Configure secure message forwarding keys, certs etc.

	sed -i -e '/\[\ v3_ca\ \]/a subjectAltName\ \=\ IP\:\ 172\.28\.128\.100' /etc/pki/tls/openssl.cnf
	cd /etc/pki/tls
	sudo openssl req -config /etc/pki/tls/openssl.cnf -x509 -days 3650 -batch -nodes -newkey rsa:2048 -keyout private/logstash-forwarder.key -out certs/logstash-forwarder.crt

	

	# Set services to start on boot
	
	chkconfig --add logstash
	chkconfig --add nginx
	chkconfig --add elasticsearch

	# Start 'em up

	service elasticsearch start
	service logstash start
	service nginx start
	
