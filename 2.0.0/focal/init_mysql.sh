#!/bin/bash

declare -g DATADIR SOCKET
#DATADIR="$(mysql_get_config 'datadir' "mariadbd")"
#SOCKET="$(mysql_get_config 'socket' "mariadbd")"
DATADIR='/var/lib/mysql'
SOCKET='/var/run/mysqld/mysqld.sock'
declare -g DATABASE_ALREADY_EXISTS
if [[ -d "$DATADIR/mysql" ]]; then
    DATABASE_ALREADY_EXISTS='true'
fi

initDatabase() {
    echo "Initializing database"
    rm -rf /var/lib/mysql
    mkdir /var/lib/mysql
    chown -vR mysql:mysql /var/lib/mysql
    chmod 777 /tmp
    sudo -u mysql mysql_install_db
    sudo -u mysql mariadbd --skip-networking --default-time-zone=SYSTEM --socket=${SOCKET} --wsrep_on=OFF &
    echo "Waiting for server startup"
    local i
    for i in {30..0}; do
        if mysql --protocol=socket -uroot -hlocalhost --socket=${SOCKET} --database=mysql <<<'SELECT 1' &> /dev/null; then
            break
        fi
        sleep 1
    done
}

initDatabase

mysql_cmd="mysql -uroot -hlocalhost --socket=${SOCKET}"
echo 'update mysql.user set plugin="" where User="root"; flush privileges; ' | $mysql_cmd

MARIADB_ROOT_PASSWORD='paloalto'
export MARIADB_ROOT_PASSWORD MYSQL_ROOT_PASSWORD=$MARIADB_ROOT_PASSWORD
mysql --protocol=socket -uroot -hlocalhost --socket=${SOCKET} --database=mysql --binary-mode <<EOSQL
    -- What's done in this file shouldn't be replicated
    --  or products like mysql-fabric won't work
    SET @@SESSION.SQL_LOG_BIN=0;
    -- we need the SQL_MODE NO_BACKSLASH_ESCAPES mode to be clear for the password to be set
    SET @@SESSION.SQL_MODE=REPLACE(@@SESSION.SQL_MODE, 'NO_BACKSLASH_ESCAPES', '');

    DELETE FROM mysql.user WHERE user NOT IN ('mysql.sys', 'mariadb.sys', 'mysqlxsys', 'root') OR host NOT IN ('localhost') ;
    SET PASSWORD FOR 'root'@'localhost'=PASSWORD('${MARIADB_ROOT_PASSWORD}') ;
    DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%' ;
    GRANT ALL ON *.* TO 'root'@'localhost' WITH GRANT OPTION ;
    FLUSH PRIVILEGES ;
    DROP DATABASE IF EXISTS test ;
EOSQL

mysql_cmd="mysql -uroot -ppaloalto -hlocalhost --socket=${SOCKET}"
$mysql_cmd -e "CREATE DATABASE pandb"
$mysql_cmd -e "CREATE DATABASE pandbRBAC"
$mysql_cmd -e "CREATE DATABASE BestPractices"
$mysql_cmd -e "CREATE DATABASE RealTimeUpdates"

cd /build
tar -zxvf databases.tgz
$mysql_cmd -uroot -ppaloalto pandb < /build/databases/pandb.sql
$mysql_cmd -uroot -ppaloalto pandbRBAC < /build/databases/pandbRBAC.sql
$mysql_cmd -uroot -ppaloalto BestPractices < /build/databases/BestPractices.sql
$mysql_cmd -uroot -ppaloalto RealTimeUpdates < /build/databases/RealTimeUpdates.sql

cd /

killall mariadbd
exit 0

