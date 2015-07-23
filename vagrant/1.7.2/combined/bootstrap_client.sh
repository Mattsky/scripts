        echo Installing.
        date > /etc/systembuild
        echo '172.28.128.100    puppet puppet-server puppet-server.localdomain' >> /etc/hosts
        rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-el-6.noarch.rpm
        yum clean all
        yum -y install puppet
        sed -i -e 's/=permissive/=disabled/' /etc/selinux/config
        chkconfig puppet on
        reboot
