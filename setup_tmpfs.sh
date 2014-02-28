echo "tmpfs /var/run tmpfs rw,nosuid,nodev,size=20M 0 0" >> /etc/fstab
echo "tmpfs /tmp tmpfs rw,nosuid,nodev,size=100M 0 0" >> /etc/fstab
echo "tmpfs /var/tmp tmpfs rw,nosuid,nodev,size=100M 0 0" >> /etc/fstab
echo "tmpfs /var/lib/php5 tmpfs rw,nosuid,nodev,size=100M 0 0" >> /etc/fstab
