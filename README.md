Základní zabezpečení LAMP serveru
=================================


Skript usnadňuje základní nastavení a zabezpečení LAMP serveru.


## Instalace

nejsnáze instalací serveru ze šablony virtualmaster:

    apt-get -y install ca-certificates apache2-mpm-prefork libapache2-mod-php5 php-db php-pear php5-cli php5-common php5-gd php5-mcrypt php5-mysql php5-suhosin php5-xcache mysql-server build-essential dialog patch ufw sudo nagios-plugins-basic pwgen
    apt-get clean

    wget -O /usr/local/sbin/wizard.sh https://raw.github.com/phokz/server-setup-wizard/master/wizard.sh
    wget -O /usr/local/sbin/first.sh https://raw.github.com/phokz/server-setup-wizard/master/first.sh
    chmod +x /usr/local/sbin/wizard.sh /usr/local/sbin/first.sh

    echo first.sh >> /root/.profile


