FROM metabrainz/base-image:v0.9.19-1

ENV HOME /root
CMD ["/sbin/my_init"]
EXPOSE 80 443

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update -q && \
	apt-get -yq -o Dpkg::Options::="--force-confold" dist-upgrade \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN echo "deb http://ppa.launchpad.net/nginx/development/ubuntu $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/nginx-development.list
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C300EE8C
RUN add-apt-repository universe && add-apt-repository multiverse
RUN apt-get update -q && \
    apt-get install --no-install-suggests -qy mysql-client nginx php7.0-cli php7.0-gd php7.0-fpm php7.0-json \
                        php7.0-mysql php7.0-curl php7.0-mbstring wget && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir /etc/service/nginx
ADD runit/nginx.sh /etc/service/nginx/run

RUN mkdir /etc/service/php-fpm
ADD runit/php-fpm.sh /etc/service/php-fpm/run

ADD config/nginx.conf /etc/nginx/nginx.conf
ADD config/nginx-default.conf /etc/nginx/sites-available/default
ADD config/php.ini /etc/php/7.0/fpm/php.ini

RUN cd /usr/share/nginx/html && \
    export PIWIK_VERSION=3.0.1 && \
    wget http://builds.piwik.org/piwik-${PIWIK_VERSION}.tar.gz && \
    tar -xzf piwik-${PIWIK_VERSION}.tar.gz && \
    rm piwik-${PIWIK_VERSION}.tar.gz && \
    mv piwik/* . && \
    rm -r piwik && \
    chown -R www-data:www-data /usr/share/nginx/html && \
    chmod 0770 /usr/share/nginx/html/tmp && \
    chmod 0770 /usr/share/nginx/html/config && \
    chmod 0600 /usr/share/nginx/html/config/* && \
    rm /usr/share/nginx/html/index.html

# Install MaxMind GeoCity Lite database
RUN cd /usr/share/nginx/html/misc && \
    wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz && \
    gunzip GeoLiteCity.dat.gz && \
    chown www-data:www-data GeoLiteCity.dat && \
	mv GeoLiteCity.dat GeoIPCity.dat

ADD config/piwik-schema.sql /usr/share/nginx/html/config/base-schema.sql

ADD scripts/generate-certs.sh /etc/my_init.d/05-certs.sh
ADD scripts/init-piwik.sh /etc/my_init.d/10-piwik.sh

RUN touch /etc/service/sshd/down
