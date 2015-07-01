#!/bin/bash

# Script to get Graphite nominally installed and operational on RHEL based systems.

# Sanity checks...

if [ "$(id -u)" != "0" ]; then
        echo "This script must be run as root."
        exit 1
fi

if [ -f local_settings.py ]; then
	echo "Settings file found - OK."
else
	echo "Settings file missing! Exiting."
	exit 1
fi

if [ -f carbon.conf ]; then
	echo "Carbon config file found - OK."
else
	echo "Carbon config file missing! Exiting."
	exit 1
fi

# For the sake of tidiness we're going to use a temporary build dir.

mkdir /opt/graphbuild; cp carbon.conf /opt/graphbuild; cp local_settings.py /opt/graphbuild; cd /opt/graphbuild

# Install prebuilt yum packages from repo 
yum -y install supervisor python-carbon-0.9.13-1.noarch python-graphite-web-0.9.13-1.noarch python-whisper-0.9.13-1.noarch --nogpgcheck

# Prep dedicated user
groupadd graphite
useradd -d /opt/graphite -s /bin/bash -g graphite graphite
chage -I -1 -E -1 -m -1 -M -1 -W -1 -E -1 graphite
chown -R graphite:graphite /opt/graphite/storage/

# Prep log and run dirs

mkdir /var/log/carbon; chown graphite:graphite /var/log/carbon
mkdir /var/run/carbon; chown graphite:graphite /var/run/carbon
mkdir /var/log/gunicorn\-graphite; chown -R graphite:graphite /var/log/gunicorn\-graphite
mkdir /var/run/gunicorn\-graphite; chown -R graphite:graphite /var/run/gunicorn\-graphite

# Activate supervisord after reboot
chkconfig supervisord on

# Copy config files into appropriate places

cp carbon.conf /opt/graphite/conf/carbon.conf ; chmod 755 /opt/graphite/conf/carbon.conf
cp /opt/graphite/conf/storage-schemas.conf.example /opt/graphite/conf/storage-schemas.conf ; chmod 755 /opt/graphite/conf/storage-schemas.conf
cp /opt/graphite/conf/storage-aggregation.conf.example /opt/graphite/conf/storage-aggregation.conf ; chmod 755 /opt/graphite/conf/storage-aggregation.conf
cp local_settings.py /opt/graphite/webapp/graphite/local_settings.py

# Set up DB if required
read -p "Run syncdb? " SYNCANS
if [[ $SYNCANS =~ ^[Yy]$ ]]; then
	python /opt/graphite/webapp/graphite/manage.py syncdb
fi
# Check for and assign secret key in Graphite's settings
grep -i 'secret_key' /opt/graphite/webapp/graphite/app_settings.py
if [ $? -ne 0 ]; then
	KEY=`tr -cd '[:alnum:]' < /dev/urandom | fold -w30 | head -n1`
	echo "SECRET_KEY = '$KEY'" >> /opt/graphite/webapp/graphite/app_settings.py	
fi

# Add entries to supervisor config

grep -i 'graphite-gunicorn' /etc/supervisord.conf
if [ $? -ne 0 ]; then
	echo "[program:graphite-gunicorn]" >> /etc/supervisord.conf
	echo "command=gunicorn_django --bind=0.0.0.0:8080 --log-file=/var/log/gunicorn-graphite/gunicorn.log --preload --pythonpath=/opt/graphite/webapp/graphite --settings=settings --workers=3 --pid=/var/run/gunicorn-graphite/gunicorn-graphite.pid" >> /etc/supervisord.conf
	echo "directory=/opt/graphite" >> /etc/supervisord.conf
	echo "user=graphite" >> /etc/supervisord.conf
	echo "autostart=True" >> /etc/supervisord.confe
	echo "autorestart=True" >> /etc/supervisord.conf
	echo "log_stdout=true" >> /etc/supervisord.conf
	echo "log_stderr=true" >> /etc/supervisord.conf
	echo "logfile=/var/log/gunicorn-graphite/gunicorn.out" >> /etc/supervisord.conf
	echo "logfile_maxbytes=20MB" >> /etc/supervisord.conf
	echo "logfile_backups=10" >> /etc/supervisord.conf
fi 

grep -i 'graphite-carbon-cache' /etc/supervisord.conf
if [ $? -ne 0 ]; then
	echo " " >> /etc/supervisord.conf
	echo "[program:graphite-carbon-cache]" >> /etc/supervisord.conf
	echo "; '--debug' is REQUIRED to get carbon to start in a manner that supervisord understands" >> /etc/supervisord.conf
	echo "; 'env PYTHONPATH=...' is REQUIRED because just using the 'environment' option apparently does not work" >> /etc/supervisord.conf
	echo "command=env PYTHONPATH=/opt/graphite/lib /opt/graphite/bin/carbon-cache.py --config /opt/graphite/conf/carbon.conf --pidfile=/var/run/carbon/carbon.pid --debug start" >> /etc/supervisord.conf
	echo "directory=/opt/graphite" >> /etc/supervisord.conf
	echo "environment=GRAPHITE_ROOT=/opt/graphite,GRAPHITE_CONF_DIR=/opt/graphite/conf,PYTHONPATH=/opt/graphite/lib" >> /etc/supervisord.conf
	echo "user=graphite" >> /etc/supervisord.conf
	echo "autostart=True" >> /etc/supervisord.conf
	echo "autorestart=True" >> /etc/supervisord.conf
	echo "log_stdout=true" >> /etc/supervisord.conf
	echo "log_stderr=true" >> /etc/supervisord.conf
	echo "logfile=/var/log/carbon/carbon.out" >> /etc/supervisord.conf
	echo "logfile_maxbytes=20MB" >> /etc/supervisord.conf
	echo "logfile_backups=5" >> /etc/supervisord.conf
fi

# Cleanup
# cd /root
# rm -rf /opt/graphbuild

echo "Install complete. Graphite now available on port 8080."
