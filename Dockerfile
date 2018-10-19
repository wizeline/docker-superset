FROM python:3.6-slim
MAINTAINER Tyler Fowler <tylerfowler.1337@gmail.com>

# Superset setup options
ENV SUPERSET_VERSION 0.27.0
ENV SUPERSET_HOME /superset
ENV SUP_SECRET_KEY 'thisismysecretkey'
ENV SUP_META_DB_URI "sqlite:///${SUPERSET_HOME}/superset.db"
ENV SUP_CSRF_ENABLED True
ENV MAPBOX_API_KEY ''
ENV LOAD_EXAMPLES false

ENV GUNICORN_BIND=0.0.0.0:8088
ENV GUNICORN_LIMIT_REQUEST_FIELD_SIZE=0
ENV GUNICORN_LIMIT_REQUEST_LINE=0
ENV GUNICORN_TIMEOUT=60
ENV GUNICORN_WORKERS=8
ENV GUNICORN_CMD_ARGS="-k gevent --workers ${GUNICORN_WORKERS} --timeout ${GUNICORN_TIMEOUT} --bind ${GUNICORN_BIND} --limit-request-line ${GUNICORN_LIMIT_REQUEST_LINE} --limit-request-field_size ${GUNICORN_LIMIT_REQUEST_FIELD_SIZE}"

ENV PYTHONPATH $SUPERSET_HOME:$PYTHONPATH

# admin auth details
ENV ADMIN_USERNAME admin
ENV ADMIN_FIRST_NAME admin
ENV ADMIN_LAST_NAME user
ENV ADMIN_EMAIL admin@nowhere.com
ENV ADMIN_PWD wizeline

### JAVA

# A few reasons for installing distribution-provided OpenJDK:
#
#  1. Oracle.  Licensing prevents us from redistributing the official JDK.
#
#  2. Compiling OpenJDK also requires the JDK to be installed, and it gets
#     really hairy.
#
#     For some sample build times, see Debian's buildd logs:
#       https://buildd.debian.org/status/logs.php?pkg=openjdk-8

RUN apt-get update && apt-get install -y --no-install-recommends \
		bzip2 \
		unzip \
		xz-utils \
	&& rm -rf /var/lib/apt/lists/*

# Default to UTF-8 file.encoding
ENV LANG C.UTF-8

# add a simple script that can auto-detect the appropriate JAVA_HOME value
# based on whether the JDK or only the JRE is installed
RUN { \
		echo '#!/bin/sh'; \
		echo 'set -e'; \
		echo; \
		echo 'dirname "$(dirname "$(readlink -f "$(which javac || which java)")")"'; \
	} > /usr/local/bin/docker-java-home \
	&& chmod +x /usr/local/bin/docker-java-home

# do some fancy footwork to create a JAVA_HOME that's cross-architecture-safe
RUN ln -svT "/usr/lib/jvm/java-8-openjdk-$(dpkg --print-architecture)" /docker-java-home
ENV JAVA_HOME /docker-java-home

ENV JAVA_VERSION 8u181
ENV JAVA_DEBIAN_VERSION 8u181-b13-1~deb9u1

# see https://bugs.debian.org/775775
# and https://github.com/docker-library/java/issues/19#issuecomment-70546872
ENV CA_CERTIFICATES_JAVA_VERSION 20170531+nmu1

RUN set -ex; \
	\
# deal with slim variants not having man page directories (which causes "update-alternatives" to fail)
	if [ ! -d /usr/share/man/man1 ]; then \
		mkdir -p /usr/share/man/man1; \
	fi; \
	\
	apt-get update; \
	apt-get install -y --no-install-recommends \
		openjdk-8-jdk-headless="$JAVA_DEBIAN_VERSION" \
		ca-certificates-java="$CA_CERTIFICATES_JAVA_VERSION" \
	; \
	rm -rf /var/lib/apt/lists/*; \
	\
# verify that "docker-java-home" returns what we expect
	[ "$(readlink -f "$JAVA_HOME")" = "$(docker-java-home)" ]; \
	\
# update-alternatives so that future installs of other OpenJDK versions don't change /usr/bin/java
	update-alternatives --get-selections | awk -v home="$(readlink -f "$JAVA_HOME")" 'index($3, home) == 1 { $2 = "manual"; print | "update-alternatives --set-selections" }'; \
# ... and verify that it actually worked for one of the alternatives we care about
	update-alternatives --query java | grep -q 'Status: manual'

# see CA_CERTIFICATES_JAVA_VERSION notes above
RUN /var/lib/dpkg/info/ca-certificates-java.postinst configure

### JAVA


# by default only includes PostgreSQL because I'm selfish
ENV DB_PACKAGES libpq-dev
ENV DB_PIP_PACKAGES psycopg2-binary sqlalchemy-redshift "PyAthenaJDBC>1.0.9" "PyAthena>1.2.0"

RUN apt-get update \
    && \
    apt-get install -y \
      build-essential gcc \
      libssl-dev \
      libffi-dev \
      libsasl2-dev \
      libldap2-dev \
    && \
    pip install --no-cache-dir \
      $DB_PIP_PACKAGES \
      "botocore<1.8.0,>=1.7.0" \
      boto3==1.4.7 \
      gevent \
      click==6.7 \
      markdown==2.6.11 \
      superset==$SUPERSET_VERSION \
    && \
    apt-get remove -y \
      build-essential \
      libssl-dev \
      libffi-dev \
      libsasl2-dev \
      libldap2-dev \
    && \
    apt-get -y autoremove \
    && \
    apt-get clean \
    && \
    rm -rf /var/lib/apt/lists/*

# install DB packages separately
RUN apt-get update \
    && \
    apt-get install -y $DB_PACKAGES \
    && \
    apt-get autoremove -y \
    && \
    apt-get clean \
    && \
    rm -rf /var/lib/apt/lists/*

# remove build dependencies
RUN mkdir $SUPERSET_HOME

COPY superset-init.sh /superset-init.sh
RUN chmod +x /superset-init.sh

VOLUME $SUPERSET_HOME
EXPOSE 8088

# since this can be used as a base image adding the file /docker-entrypoint.sh
# is all you need to do and it will be run *before* Superset is set up
ENTRYPOINT [ "/superset-init.sh" ]
