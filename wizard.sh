#!/bin/bash

export LC_ALL=en_US.utf8
dialog --title "NO WARRANTY | ŽÁDNÁ ZǍRUKA" --yesno "Tento skript je poskytnut tak jak je bez jakékoliv záruky. Používáte jej na vlastní riziko. Tento skript vám mimo jiné může sežrat křečka. Chcete přesto pokračovat?" 10 40

if [ $? = 0 ]; then
  echo "Jedeme dál"
  echo "chomp chomp munch munch stomp stomp"
else
 echo "Profesore Křečku, nechtějí vás nechat sežrat."
 exit
fi

# overi, ze existuje bezny uzivatel
p=`ls /home | wc -l`
if [ $p = 0 ]; then
  # pokud ne, nabidne jeho zalozeni

  dialog --title "Non-root uživatel"  --yesno "Neexistuje žádný non-root uživatel. Chcete ho založit?" 10 40
  if [ $? = 0 ]; then
    dialog --inputbox "Zadejte uživatelské jméno:" 10 60 2>/tmp/answer
    useradd -s /bin/bash -m `cat /tmp/answer`
    usermod -G sudo -a `cat /tmp/answer`
  fi

fi


# overi, ze ma ssh klic
p=`ls -l /home/*/.ssh/authorized_keys | wc -l`
if [ $p = 0 ]; then
  # pokud ne, nabidne jeho vlozeni
  dialog --title "SSH klíče"  --yesno "Žádný z uživatelů nemá ssh klíč. Chcete jej nyní vložit?" 10 40
  cd /home
  for i in *; do
    mkdir /home/$i/.ssh
    dialog --inputbox "Vložte ssh klíč uživatele $i:" 10 60 2>/home/$i/.ssh/authorized_keys
    chown -R $i:$i /home/$i/.ssh
    chmod 600 /home/$i/.ssh/authorized_keys 
    chmod 700 /home/$i/.ssh
  done 
fi


# nastavi ssh prihlaseni pouze klicema
dialog --title "SSH pouze klíčem"  --yesno "Doporučuje se k přihlašování k ssh serveru používat klíče a zakázat přihlašování jako root. Chcete to tak nastavit?" 10 40

if [ $? = 0 ]; then
  sed -i -e 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
  sed -i -e 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
  /etc/init.d/ssh restart

  else
  echo "Komu není rady, tomu není pomoci."
fi


dialog --title "Firewall"  --yesno "Chcete nastavit základní firewall (povoleno 22,80,443)?" 10 40

if [ $? = 0 ]; then
  sed -i s/IPV6=no/IPV6=yes/ /etc/default/ufw
  ufw allow 80/tcp
  ufw allow 443/tcp
  ufw allow 22/tcp
  ufw --force enable
fi


dialog --title "SFTP server" --yesno "Chcete nastavit sftp server s chrootem a přihlašováním klíči?" 10 40
if [ $? = 0 ]; then

sed -i "s/Subsystem sftp /#Subsystem sftp /" /etc/ssh/sshd_config

cat >> /etc/ssh/sshd_config <<EOF
AuthorizedKeysFile /etc/ssh-keys/%u.pub
ChrootDirectory /var/www/%u
AllowTcpForwarding no
Subsystem sftp internal-sftp

Match Group admin
   ChrootDirectory none
   AllowTcpForwarding yes
EOF

mkdir -p /etc/ssh-keys
groupadd admin

cd /home
for i in *; do 
  usermod -G admin -a $i
  cp /home/$i/.ssh/authorized_keys /etc/ssh-keys/$i.pub
done

cp /root/.ssh/authorized_keys /etc/ssh-keys/root.pub

/etc/init.d/ssh restart

cat > /tmp/sftp-only.c <<EOF
#include <stdio.h>
int main() {
 printf("Only sftp access is allowed. Get sftp, or http://winscp.net/ and try again.\n");
 return 0;
}
EOF

gcc -Wall -W -Os -static -o /tmp/sftp-only /tmp/sftp-only.c
strip /tmp/sftp-only

fi


#chcete zalozit uzivatele se sftp pristupem?
dialog --title "SFTP server" --yesno "Chcete založit pokusného sftp uživatele?" 10 40

if [ $? = 0 ]; then
  useradd -d /www.domena.cz sftptest
  mkdir /var/www/sftptest
  mkdir /var/www/sftptest/bin
  mkdir /var/www/sftptest/www.domena.cz
  cp /tmp/sftp-only /var/www/sftptest/bin/sh
  
  chown sftptest:sftptest /var/www/sftptest/www.domena.cz
  cat /etc/ssh-keys/* >> /etc/ssh-keys/sftptest.pub

  . /etc/virtualmaster.cfg.disabled

  dialog --title 'Hotovo.' --msgbox "Nyní se můžete zkusit připojit na sftptest@$virtualmaster_ipv4_address" 10 60

fi


#chcete nainstalovat adminer?
dialog --title "Adminer - web přístup k MySQL" --yesno "Chcete nainstalovat adminer?" 10 40
if [ $? = 0 ]; then

  wget -O /var/www/adminer.php http://downloads.sourceforge.net/adminer/adminer-3.3.3.php
  echo "Adminer je přístupný na http://$virtualmaster_ipv4_address/adminer.php"

fi


dialog --title "SSL/TLS zabezpečení apache2" --yesno "Chcete zabezpečit apache2 pomocí SSL/TLS (https) ?" 10 40
if [ $? = 0 ]; then

#chcete vytvoit csr?
  mkdir -p /root/pki
  cd /root/pki
  h=`hostname -f`

  export KEY_COUNTRY=CZ
  export KEY_PROVINCE="Czech Republic"
  export KEY_CITY=Prague
  export KEY_CN=$h

  openssl genrsa -out $h.key 4096
  openssl req -new -key $h.key -out $h.csr

  cp $h.key /etc/ssl/private/
  chmod 640 /etc/ssl/private/$h.key
  chown root:ssl-cert /etc/ssl/private/$h.key

  cat $h.csr
  echo "Nyní si okopírujte požadavek na vystavení podepsaného certifikátu a certifikát si nechte podepsat."
  echo "Můžete zkusit třeba freessl.com nebo startssl.com."
  echo "Stiskněte Enter"
  read a


  echo "Podepsaný certifikát umístěte do /etc/ssl/certs/$h.crt"
  echo "Stiskněte Enter"
  read a

  a2enmod ssl
  a2ensite default-ssl

cd /etc/apache2/sites-available
(cat <<EOF
--- /etc/apache2/sites-available/default-ssl	2011-09-26 14:49:00.000000000 +0200
+++ /etc/apache2/sites-available/default-ssl	2011-09-26 14:48:37.000000000 +0200
@@ -42,6 +42,8 @@
 	#   SSL Engine Switch:
 	#   Enable/Disable SSL for this virtual host.
 	SSLEngine on
+	SSLProtocol -ALL +SSLv3 +TLSv1
+	SSLCipherSuite ALL:!aNULL:!ADH:!DH:!EDH:!eNULL:!LOW:!EXP:RC4+RSA:+HIGH
 
 	#   A self-signed (snakeoil) certificate can be created by installing
 	#   the ssl-cert package. See
EOF
) | patch

  /etc/init.d/apache2 restart

dialog --title "SSL/TLS konfigurace apache2" --yesno "Máte-li podepsaný certifikát uložený v /etc/ssl/certs/$h.crt, je možné přenastavit apache2 aby používal tento certifikát. Jinak poběží se self-signed 'SnakeOil' certifikátem. Je možné přepnout apache2 na podepsaný certifikát? " 12 60
if [ $? = 0 ]; then

  sed -i s/ssl-cert-snakeoil.pem/$h.crt/ /etc/apache2/sites-available/default-ssl
  sed -i s/ssl-cert-snakeoil.key/$h.key/ /etc/apache2/sites-available/default-ssl
  /etc/init.d/apache2 restart

fi

dialog --title 'Hotovo.' --msgbox "Nyní se můžete zkusit připojit na Váš server přes https. Můžete také otestovat úroveň zabezpečení pomocí https://www.ssllabs.com/ssldb/" 10 60
fi


dialog --title "Nastavení limitů mysql" --yesno "Chcete nastavit decentní limity mysql?" 10 40

if [ $? = 0 ]; then

#TODO:
 #zmena hesla v db
 #FIXME - fixed by hook to /etc/rc.local

 #nastaveni max_clients a dalsich tak, aby se mysql vesla do 128M ram

 sed -i "s/key_buffer\t\t= 16M/key_buffer\t\t= 4M/" /etc/mysql/my.cnf
 sed -i 's/#max_connections        = 100/max_connections        = 20/' /etc/mysql/my.cnf
 sed -i 's/query_cache_size        = 16M/query_cache_size        = 4M/' /etc/mysql/my.cnf

 /etc/init.d/mysql restart

 wget -O /usr/local/sbin/mysqltuner.pl mysqltuner.pl

 chmod +x /usr/local/sbin/mysqltuner.pl

 /usr/local/sbin/mysqltuner.pl

 echo "Stiskněte enter."
 read a

fi

dialog --title "Nastavení limitů webserver" --yesno "Chcete nastavit decentní limity apache2/php?" 10 40

if [ $? = 0 ]; then

  sed -i 's/memory_limit = 128M/memory_limit = 12M/' /etc/php5/apache2/php.ini
  sed -i 's/MaxClients          150/MaxClients          15/g' /etc/apache2/apache2.conf
  sed -i 's/KeepAliveTimeout 15/KeepAliveTimeout 4/' /etc/apache2/apache2.conf

  #suhosin
  sed -i 's/;suhosin.mail.protect = 0/suhosin.mail.protect = 1/' /etc/php5/conf.d/suhosin.ini
  sed -i 's/;suhosin.memory_limit = 0/suhosin.memory_limit = 12M/' /etc/php5/conf.d/suhosin.ini
  sed -i 's/;suhosin.executor.disable_eval = off/;suhosin.executor.disable_eval = on/' /etc/php5/conf.d/suhosin.ini

  /etc/init.d/apache2 restart

fi

dialog --title 'Hotovo.' --msgbox "Jsme u konce. Nyní můžete prozkoumat, co a jak tento průvodce nastavil. Zdrojový kód naleznete mimo jiné na githubu: https://github.com/phokz/server-setup-wizard" 10 60

