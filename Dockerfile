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

# by default only includes PostgreSQL because I'm selfish
ENV DB_PACKAGES libpq-dev
ENV DB_PIP_PACKAGES psycopg2-binary sqlalchemy-redshift

RUN apt-get update \
&& apt-get install -y \
  build-essential gcc \
  libssl-dev libffi-dev libsasl2-dev libldap2-dev \
&& pip install --no-cache-dir \
  $DB_PIP_PACKAGES gevent click==6.7 markdown==2.6.11 superset==$SUPERSET_VERSION \
&& apt-get remove -y \
  build-essential libssl-dev libffi-dev libsasl2-dev libldap2-dev \
&& apt-get -y autoremove && apt-get clean && rm -rf /var/lib/apt/lists/*

# install DB packages separately
RUN apt-get update && apt-get install -y $DB_PACKAGES \
&& apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*

# remove build dependencies
RUN mkdir $SUPERSET_HOME

COPY superset-init.sh /superset-init.sh
RUN chmod +x /superset-init.sh

VOLUME $SUPERSET_HOME
EXPOSE 8088

# since this can be used as a base image adding the file /docker-entrypoint.sh
# is all you need to do and it will be run *before* Superset is set up
ENTRYPOINT [ "/superset-init.sh" ]
