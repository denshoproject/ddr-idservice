# After installing (FPM) .deb package, make logs directory
mkdir /var/log/ddr
touch /var/log/ddr/idservice.log
touch /var/log/ddr/ddridservice.log
chmod 755 /var/log/ddr
chown -R ddr:ddr /var/log/ddr

# Copy ddr-cmdln config
cp /opt/ddr-cmdln/conf/ddrlocal.cfg /etc/ddr/
