#!/bin/bash

set -eo pipefail

# check to see if the superset config already exists, if it does skip to
# running the user supplied docker-entrypoint.sh, note that this means
# that users can copy over a prewritten superset config and that will be used
# without being modified
echo "Checking for existing Superset config..."
if [ ! -f $SUPERSET_HOME/superset_config.py ]; then
  echo "No Superset config found, creating from environment"
  touch $SUPERSET_HOME/superset_config.py

  cat > $SUPERSET_HOME/superset_config.py <<EOF
SECRET_KEY = '${SUP_SECRET_KEY}'
SQLALCHEMY_DATABASE_URI = '${SUP_META_DB_URI}'
CSRF_ENABLED = ${SUP_CSRF_ENABLED}
MAPBOX_API_KEY = '${MAPBOX_API_KEY}'
EOF
fi

# check for existence of /docker-entrypoint.sh & run it if it does
echo "Checking for docker-entrypoint"
if [ -f /docker-entrypoint.sh ]; then
  echo "docker-entrypoint found, running"
  chmod +x /docker-entrypoint.sh
  . docker-entrypoint.sh
fi

# set up Superset if we haven't already
if [ ! -f $SUPERSET_HOME/.setup-complete ]; then
  echo "Running first time setup for Superset"

  echo "Creating admin user ${ADMIN_USERNAME}"
  cat > $SUPERSET_HOME/admin.config <<EOF
${ADMIN_USERNAME}
${ADMIN_FIRST_NAME}
${ADMIN_LAST_NAME}
${ADMIN_EMAIL}
${ADMIN_PWD}
${ADMIN_PWD}

EOF

  /bin/sh -c '/usr/local/bin/fabmanager create-admin --app superset < $SUPERSET_HOME/admin.config'

  rm $SUPERSET_HOME/admin.config

  echo "Initializing database"
  superset db upgrade

  echo "Creating default roles and permissions"
  superset init

  echo "LOAD_EXAMPLES ${LOAD_EXAMPLES}"
  if [ ${LOAD_EXAMPLES} == true ]; then
    echo "Load example data"
    superset load_examples
  fi

  touch $SUPERSET_HOME/.setup-complete
else
  # always upgrade the database, running any pending migrations
  superset db upgrade
fi

echo "Starting up Superset"
#superset runserver -p 8088 -a 0.0.0.0 -t ${SUP_WEBSERVER_TIMEOUT}
gunicorn superset:app 
