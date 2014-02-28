Základní zabezpečení LAMP serveru
=================================


Skript usnadňuje základní nastavení a zabezpečení LAMP serveru.


## Instalace

nejsnáze instalací serveru ze šablony virtualmaster: https://www.virtualmaster.cz/cs/images/detail/1701

## Instalace z čistého debian systému

Např. https://www.virtualmaster.com/virtualmaster/cs/images/detail/3499

- instalace balíčků

```
    apt-get -y install ca-certificates apache2-mpm-prefork libapache2-mod-php5 php-db php-pear php5-cli php5-common php5-gd php5-mcrypt php5-mysql php5-suhosin php5-xcache mysql-server build-essential dialog patch ufw sudo nagios-plugins-basic pwgen
    apt-get clean
```

- instalace skriptu

```
    wget -O /usr/local/sbin/wizard.sh https://raw.github.com/phokz/server-setup-wizard/master/wizard.sh
    wget -O /usr/local/sbin/first.sh https://raw.github.com/phokz/server-setup-wizard/master/first.sh
    wget -O /usr/local/sbin/fix_mysql_passwords https://raw.github.com/phokz/server-setup-wizard/master/fix_mysql_passwords

    chmod +x /usr/local/sbin/wizard.sh /usr/local/sbin/first.sh /usr/local/sbin/fix_mysql_passwords

    echo first.sh >> /root/.profile
    sed -i 's/^exit 0/\/usr\/local\/sbin\/fix_mysql_passwords\nexit 0/' /etc/rc.local
    touch /etc/mysql/change_password
```

### Nyní uložit jako šablonu


