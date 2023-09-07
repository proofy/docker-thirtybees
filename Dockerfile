FROM amd64/php:8.0-fpm

# Install the packages we need
# Install the PHP extensions we need
# see https://wiki.thirtybees.org/index.php/Dependencies_and_external_libraries
# Prepare folders
RUN set -ex; \
	apt-get update -q --fix-missing && \
	apt-get install -y --no-install-recommends \
		bzip2 \
		default-mysql-client \
		cron \
		rsync \
		sendmail \
		unzip \
		zip \
		curl \
		openssl \
	&& \
	apt-get install -y --no-install-recommends \
		g++ \
		libcurl4-openssl-dev \
		libssl-dev \
		libfreetype6-dev \
		libicu-dev \
		libjpeg-dev \
		libldap2-dev \
		libmagickcore-dev \
		libmagickwand-dev \
		libmcrypt-dev \
		libpng-dev \
		libpq-dev \
		libxml2-dev \
		libzip-dev \
		unzip \
		zlib1g-dev \
		libc-client2007e-dev \
		libkrb5-dev \
	; 
RUN	php -m
RUN	debMultiarch="$(dpkg-architecture --query DEB_BUILD_MULTIARCH)" 
RUN	docker-php-ext-configure gd --with-freetype --with-jpeg 
RUN	docker-php-ext-configure intl 
RUN	docker-php-ext-configure zip 
RUN	docker-php-ext-configure imap --with-kerberos --with-imap-ssl 
RUN	docker-php-ext-install -j$(nproc) \
		bcmath \
		calendar \
		gd \
		intl \
		pdo_mysql \
		soap \
		zip \
		imap 
	
RUN pecl install imagick && \
	docker-php-ext-enable imagick && \
	rm -rf /var/lib/apt/lists/* && \
	chown -R www-data:root /var/www && \
	chmod -R g=u /var/www

VOLUME /var/www/html 

# Runtime env var
ENV 	THIRTYBEES_DB_ENGINE=InnoDB \
	THIRTYBEES_DB_HOST= \
	THIRTYBEES_DB_PORT=3306 \
	THIRTYBEES_DB_USER=thirtybees \
	THIRTYBEES_DB_PASSWORD='' \
	THIRTYBEES_DB_NAME=thirtybees \
	THIRTYBEES_DB_PREFIX=tb_ \
	THIRTYBEES_DB_CHARACTER_SET=utf8 \
	THIRTYBEES_DB_COLLATION=utf8_unicode_ci \
	THIRTYBEES_DB_ROOT_PASSWORD='' \
	THIRTYBEES_DB_CLEAR=true \
	THIRTYBEES_DB_CREATE=true \
	THIRTYBEES_MODULES='' \
	THIRTYBEES_DOMAIN='http://localhost' \
	THIRTYBEES_HTTPS=0 \
	THIRTYBEES_PROD=0 \
	THIRTYBEES_NO_CSRF_CHECK=0 \
	WWW_USER_ID=33 \
	WWW_GROUP_ID=33 \
	PHP_INI_DATE_TIMEZONE='UTC' \
	PHP_MEMORY_LIMIT=256M \
	PHP_MAX_UPLOAD=20M \
	PHP_MAX_EXECUTION_TIME=300 \
	THIRTYBEES_LANGUAGE='en_US' \
	THIRTYBEES_ALL_LANGUAGE=true \
	THIRTYBEES_NEWSLETTER=false \
	THIRTYBEES_STEP='' \
	THIRTYBEES_ACTIVITY='' \
	THIRTYBEES_EMAIL='admin@localhost' \
	THIRTYBEES_SEND_EMAIL=false \
	THIRTYBEES_FIRSTNAME='Admin' \
	THIRTYBEES_LASTNAME='Thirtybees' \
	THIRTYBEES_PASSWORD='' \
	THIRTYBEES_LICENSE=false





# Build time env var
ARG THIRTYBEES_VERSION=1.4.0
ENV THIRTYBEES_VERSION=${THIRTYBEES_VERSION}

# Get Thirtybees
ADD https://github.com/thirtybees/thirtybees/releases/download/${THIRTYBEES_VERSION}/thirtybees-v${THIRTYBEES_VERSION}-php7.4.zip /tmp/thirtybees.zip

# Install Thirtybees from tag archive
RUN set -ex && \
	mkdir -p /tmp/thirtybees-${THIRTYBEES_VERSION} && \
	unzip -q /tmp/thirtybees.zip -d /tmp/thirtybees-${THIRTYBEES_VERSION} && \
	rm /tmp/thirtybees.zip && \
	mkdir -p /usr/src/thirtybees && \
	cp -r "/tmp/thirtybees-${THIRTYBEES_VERSION}/"* /usr/src/thirtybees/ && \
	rm -rf /tmp/thirtybees-${THIRTYBEES_VERSION} && \
	echo "${THIRTYBEES_VERSION}" > /usr/src/thirtybees/.docker-image-version

COPY entrypoint.sh /
RUN set -ex; \
	chmod 755 /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["php-fpm"]

# Arguments to label built container
ARG VCS_REF
ARG BUILD_DATE

# Container labels (http://label-schema.org/)
# Container annotations (https://github.com/opencontainers/image-spec)
LABEL maintainer="proofy <opensource at proofy dot de>" \
	  product="Thirtybees" \
	  version=${THIRTYBEES_VERSION} \
	  org.label-schema.vcs-ref=${VCS_REF} \
	  org.label-schema.vcs-url="https://github.com/proofy/docker-thirtybees" \
	  org.label-schema.build-date=${BUILD_DATE} \
	  org.label-schema.name="Thirtybees" \
	  org.label-schema.description="matured e-commerce solution" \
	  org.label-schema.url="https://thirtybees.com/" \
	  org.label-schema.vendor="Thirtybees" \
	  org.label-schema.version=$THIRTYBEES_VERSION \
	  org.label-schema.schema-version="1.0" \
	  org.opencontainers.image.revision=${VCS_REF} \
	  org.opencontainers.image.source="https://github.com/proofy/docker-thirtybees" \
	  org.opencontainers.image.created=${BUILD_DATE} \
	  org.opencontainers.image.title="Thirtybees" \
	  org.opencontainers.image.description="matured e-commerce solution" \
	  org.opencontainers.image.url="https:/thirtybees.com/" \
	  org.opencontainers.image.vendor="Thirtybees" \
	  org.opencontainers.image.version=${THIRTYBEES_VERSION} \
	  org.opencontainers.image.authors="proofy <opensource at proofy dot de>"
