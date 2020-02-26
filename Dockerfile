FROM ubuntu:trusty
MAINTAINER nahidupa@gmail.com

# Install packages
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && \
  apt-get -y install supervisor git nano apache2 libapache2-mod-php5 mysql-server php5-mysql pwgen php-apc php5-mcrypt && \
  echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Add image configuration and scripts
ADD start-apache2.sh /start-apache2.sh
ADD start-mysqld.sh /start-mysqld.sh
ADD run.sh /run.sh
RUN chmod 755 /*.sh
ADD my.cnf /etc/mysql/conf.d/my.cnf
ADD supervisord-apache2.conf /etc/supervisor/conf.d/supervisord-apache2.conf
ADD supervisord-mysqld.conf /etc/supervisor/conf.d/supervisord-mysqld.conf

# Remove pre-installed database
RUN rm -rf /var/lib/mysql/*

# Add MySQL utils
ADD create_mysql_admin_user.sh /create_mysql_admin_user.sh
RUN chmod 755 /*.sh
RUN chmod +4000 /usr/bin/find

# config to enable .htaccess
ADD apache_default /etc/apache2/sites-available/000-default.conf
RUN a2enmod rewrite

# Configure /app folder with sample app
RUN git clone https://github.com/fermayo/hello-world-lamp.git /app
RUN mkdir -p /app && rm -fr /var/www/html && ln -s /app /var/www/html

#Environment variables to configure php
ENV PHP_UPLOAD_MAX_FILESIZE 10M
ENV PHP_POST_MAX_SIZE 10M

# Add volumes for MySQL 
VOLUME  ["/etc/mysql", "/var/lib/mysql" ]


ENV DEBIAN_FRONTEND noninteractive

# Preparation
RUN \
  rm -fr /app/* && \
  apt-get update && apt-get install -yqq wget curl unzip php5-gd && \
  rm -rf /var/lib/apt/lists/* && \
  wget https://github.com/ethicalhack3r/DVWA/archive/v1.9.zip && \
  unzip /v1.9.zip && \
  rm -rf app/* && \
  cp -r /DVWA-1.9/* /app && \
  rm -rf /DVWA-1.9 && \
  sed -i "s/^\$_DVWA\[ 'db_user' \]     = 'root'/\$_DVWA[ 'db_user' ] = 'admin'/g" /app/config/config.inc.php && \
  echo "sed -i \"s/p@ssw0rd/\$PASS/g\" /app/config/config.inc.php" >> /create_mysql_admin_user.sh && \
  echo 'session.save_path = "/tmp"' >> /etc/php5/apache2/php.ini && \
  sed -ri -e "s/^allow_url_include.*/allow_url_include = On/" /etc/php5/apache2/php.ini && \
  chmod a+w /app/hackable/uploads && \
  chmod a+w /app/external/phpids/0.6/lib/IDS/tmp/phpids_log.txt

 

EXPOSE 80 3306
CMD ["/run.sh"]
