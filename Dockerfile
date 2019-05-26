# nginx docker für rpi arm32v6
FROM arm32v6/nginx:stable-alpine

# set version label
ARG BUILD_DATE
ARG VERSION
ARG CERTBOT_VERSION
ARG OVERLAY_VERSION="v1.22.1.0"
ARG OVERLAY_ARCH="armhf"
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"

# environment settings
ENV DHLEVEL=2048 ONLY_SUBDOMAINS=false AWS_CONFIG_FILE=/config/dns-conf/route53.ini
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2

RUN \ 
 echo "**** install build packages ****" && \
 apk add --no-cache --virtual=build-dependencies \
	curl \
    tar && \
 echo "**** add s6 overlay ****" && \
 curl -o \
 /tmp/s6-overlay.tar.gz -L \
	"https://github.com/just-containers/s6-overlay/releases/download/${OVERLAY_VERSION}/s6-overlay-${OVERLAY_ARCH}.tar.gz" && \
 tar xfz \
 /tmp/s6-overlay.tar.gz -C / && \
 echo "**** add qemu ****" && \
 curl -o \
 /usr/bin/qemu-arm-static -L \
	"https://lsio-ci.ams3.digitaloceanspaces.com/qemu-arm-static" && \
 chmod +x /usr/bin/qemu-arm-static && \
 echo "**** install runtime packages ****" && \
 apk add --no-cache --upgrade --force-overwrite \
# add shadow for groupmod and usermod and several other packages
	shadow \
	bash \
	ca-certificates \
	coreutils \
	shadow \
	tzdata \
	curl \
	fail2ban \
	gnupg \
	memcached \
	nginx \
	nginx-mod-http-echo \
	nginx-mod-http-fancyindex \
	nginx-mod-http-geoip \
	nginx-mod-http-headers-more \
	nginx-mod-http-image-filter \
	nginx-mod-http-lua \
	nginx-mod-http-lua-upstream \
	nginx-mod-http-nchan \
	nginx-mod-http-perl \
	nginx-mod-http-redis2 \
	nginx-mod-http-set-misc \
	nginx-mod-http-upload-progress \
	nginx-mod-http-xslt-filter \
	nginx-mod-mail \
	nginx-mod-rtmp \
	nginx-mod-stream \
	nginx-mod-stream-geoip \
	nginx-vim \
	apache2-utils \
	git \
	libressl2.7-libssl \
	logrotate \
	nano \
	openssl \
	php7 \
	php7-fileinfo \
	php7-fpm \
	php7-json \
	php7-mbstring \
	php7-openssl \
	php7-session \
    php7-simplexml \
	php7-bz2 \
	php7-ctype \
	php7-curl \
	php7-dom \
	php7-exif \
	php7-gd \
	php7-iconv \
	php7-intl \
	php7-mcrypt \
	php7-memcached \
	php7-mysqli \
	php7-mysqlnd \
	php7-opcache \
	php7-pdo_mysql \
	php7-pdo_pgsql \
	php7-pdo_sqlite \
	php7-pecl-redis \
	php7-pgsql \
	php7-phar \
	php7-posix \
	php7-soap \
	php7-sockets \
	php7-sqlite3 \
	php7-tokenizer \
	php7-xml \
	php7-xmlreader \
	php7-zip \
	py3-cryptography \
	py3-future \
	py3-pip && \
 echo "**** create abc user and make our folders ****" && \
 groupmod -g 1000 users && \
 useradd -u 911 -U -d /config -s /bin/false abc && \
 usermod -G users abc && \
 mkdir -p \
	/app \
	/config \
	/defaults && \
 echo "**** install certbot plugins ****" && \
 if [ -z ${CERTBOT_VERSION+x} ]; then \
        CERTBOT="certbot"; \
 else \
        CERTBOT="certbot==${CERTBOT_VERSION}"; \
 fi && \
 pip3 install -U \
	pip && \
 pip3 install -U \
	${CERTBOT} \
	certbot-dns-cloudflare \
	certbot-dns-cloudxns \
	certbot-dns-digitalocean \
	certbot-dns-dnsimple \
	certbot-dns-dnsmadeeasy \
	certbot-dns-google \
	certbot-dns-luadns \
	certbot-dns-nsone \
	certbot-dns-ovh \
	certbot-dns-rfc2136 \
	certbot-dns-route53 \
	requests && \
 echo "**** remove unnecessary fail2ban filters ****" && \
 rm \
	/etc/fail2ban/jail.d/alpine-ssh.conf && \
 echo "**** copy fail2ban default action and filter to /default ****" && \
 mkdir -p /defaults/fail2ban && \
 mv /etc/fail2ban/action.d /defaults/fail2ban/ && \
 mv /etc/fail2ban/filter.d /defaults/fail2ban/ && \
 echo "**** copy proxy confs to /default ****" && \
 mkdir -p /defaults/proxy-confs && \
 curl -o \
	/tmp/proxy.tar.gz -L \
	"https://github.com/linuxserver/reverse-proxy-confs/tarball/master" && \
 tar xf \
	/tmp/proxy.tar.gz -C \
	/defaults/proxy-confs --strip-components=1 --exclude=linux*/.gitattributes --exclude=linux*/.github && \
 echo "**** configure nginx ****" && \
 echo 'fastcgi_param  SCRIPT_FILENAME $document_root$fastcgi_script_name;' >> \
 /etc/nginx/fastcgi_params && \
 rm -f /etc/nginx/conf.d/default.conf && \
 rm -f /etc/nginx/conf.d/default.conf && \
 echo "**** fix logrotate ****" && \
 sed -i "s#/var/log/messages {}.*# #g" /etc/logrotate.conf && \
 echo "**** cleanup ****" && \
 for cleanfiles in *.pyc *.pyo; \
	do \
	find /usr/lib/python3.*  -iname "${cleanfiles}" -exec rm -f '{}' + \
	; done && \
 apk del --purge \
 build-dependencies && \
 rm -rf \
	/tmp/* \
	/root/.cache

# add local files
COPY root/ /

# ports and volumes
EXPOSE 80 443
VOLUME /config

# entrypoint for s6 overlay
ENTRYPOINT ["/init"]
