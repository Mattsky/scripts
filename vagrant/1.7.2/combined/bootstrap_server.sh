        echo Installing.
        date > /etc/systembuild
        rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-el-6.noarch.rpm
        yum clean all
        yum -y install puppet-server sleep
        sed -i -e '/vardir\/ssl/a dns_alt_names = puppet,puppet-server,puppet-server.localdomain' /etc/puppet/puppet.conf
        puppet master --verbose --no-daemonize &
        sleep 30
        sed -i -e 's/=permissive/=disabled/' /etc/selinux/config
        chkconfig puppetmaster on
        reboot

