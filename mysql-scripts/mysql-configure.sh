#!/bin/bash

CREATION_SCRIPT="https://github.com/apache/brooklyn-library/raw/master/examples/simple-web-cluster/src/main/resources/visitors-creation-script.sql"
# When MySQL is stopped `systemctl status mariadb` returns `Active: inactive (dead)`
# reminder: test for what you expect
sudo systemctl status mysql | grep 'dead' > /dev/null 2>&1
if [ $? != 0 ] ; then
  echo "MySQL is running when configure is called. Skipping configuration assuming it has already been done. If this is not correct then stop the DB before invoking this."
else
  echo "Configuring MySQL..."
  # When MySQL is up `systemctl status mariadb` returns `Active: active (running)`
  sudo systemctl start mysql

  if [ -f ${CREATION_SCRIPT} ] ; then
        echo "Fetching and running creation script from ${CREATION_SCRIPT_URL}..."
        curl -L -k -f -o creation-script-from-url.sql ${CREATION_SCRIPT_URL}
        sudo mysql -u root < creation-script-from-url.sql
  fi
fi