#!/bin/bash

echo '# apache2 ##########'

DIR="$(dirname "$(readlink -f "$0")")"
if [[ -z $DIR ]]; then echo 'var DIR is empty'; exit 1; fi

DISTRO=`cat $DIR/../distro/.distro`

if ! [[ -d /opt/simplecloud/_config_cache/apache2 ]]; then
	echo 'Directory not found: /opt/simplecloud/_config_cache/apache2'
	exit 1
fi
if ! [[ -d /data/simplecloud/storage ]]; then
	echo 'Directory not found: /data/simplecloud/storage'
	exit 1
fi

# install
$DIR/../distro/pm-install.sh apache2 unzip

case $DISTRO in
	'arch' )
		function a2enmod {
			sed -ie "s/#LoadModule ${1}/LoadModule ${1}/g" /etc/httpd/conf/httpd.conf
		}
	;;
esac

a2enmod access_compat
a2enmod rewrite
a2enmod dav
a2enmod dav_fs
a2enmod deflate
a2enmod headers
a2enmod proxy
a2enmod proxy_ajp
a2enmod proxy_balancer
a2enmod proxy_connect
a2enmod proxy_html
a2enmod proxy_http
a2enmod ssl
a2enmod slotmem_shm
a2enmod xml2enc

systemctl disable apache2
systemctl stop apache2

# configs
if [[ ! -d /var/www ]]; then
	mkdir /var/www
fi

if ! [[ -f /opt/simplecloud/_config_cache/apache2/config.conf ]]; then
	cp $DIR/config.default.conf /opt/simplecloud/_config_cache/apache2/config.conf
fi

mkdir /var/www/dash
unzip $DIR/simple-dash.zip -d /var/www/dash/
chmod -R 775 /var/www/dash
if ! [[ -f /opt/simplecloud/_config_cache/apache2/config.json ]]; then
	cp $DIR/config.default.json /opt/simplecloud/_config_cache/apache2/config.json
fi
ln -sf /opt/simplecloud/_config_cache/apache2/config.json /var/www/dash/

case $DISTRO in
	'suse' )
		rm /etc/apache2/vhost.d/*.conf
		ln -sf /opt/simplecloud/_config_cache/apache2/config.conf /etc/apache2/vhosts.d/
	;;
	'debian' )
		rm /etc/apache2/sites-enabled/*.conf
		ln -sf /opt/simplecloud/_config_cache/apache2/config.conf /etc/apache2/sites-enabled/
	;;
	'arch' )
		ln -sf /opt/simplecloud/_config_cache/apache2/config.conf /etc/httpd/conf/extra/enabled.conf
		if [[ -z `grep 'Include conf/extra/enabled.conf' /etc/httpd/conf/httpd.conf` ]]; then
			echo 'Include conf/extra/enabled.conf' >> /etc/httpd/conf/httpd.conf
		fi
	;;
esac

# permissions
case $DISTRO in
	'suse' )
		usermod -u 1100 wwwrun
		groupmod -g 1300 www
	;;
	'debian' )
		usermod -u 1100 www-data
		groupmod -g 1300 www-data
	;;
	'arch' )
		usermod -u 1100 http
		groupmod -g 1300 http
	;;
esac

chown 1100:root -R /data/simplecloud/storage
chown 1100:root -R /var/www/dash
