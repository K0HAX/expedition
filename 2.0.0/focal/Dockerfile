FROM ubuntu:focal
ENV DEBIAN_FRONTEND=noninteractive
RUN ln -fs /usr/share/zoneinfo/UTC /etc/localtime
RUN apt-get update
RUN apt-get -y install apt-transport-https lsb-core lsb-release net-tools netcat-openbsd sudo software-properties-common expect
RUN apt-get install -y --no-install-recommends tzdata
RUN dpkg-reconfigure --frontend noninteractive tzdata
RUN touch /usr/bin/firewall-cmd
RUN chmod +x /usr/bin/firewall-cmd
RUN useradd -m expedition
RUN add-apt-repository ppa:adiscon/v8-stable -y
RUN echo 'deb [trusted=yes] https://conversionupdates.paloaltonetworks.com/ expedition-updates/' > /etc/apt/sources.list.d/ex-repo.list
RUN curl -1sLf "https://keys.openpgp.org/vks/v1/by-fingerprint/0A9AF2115F4687BD29803A206B73A36E6026DFCA" | gpg --dearmor > /usr/share/keyrings/com.rabbitmq.team.gpg
RUN curl -1sLf "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xf77f1eda57ebb1cc" | gpg --dearmor > /usr/share/keyrings/net.launchpad.ppa.rabbitmq.erlang.gpg
RUN curl -1sLf "https://packagecloud.io/rabbitmq/rabbitmq-server/gpgkey" | gpg --dearmor > /usr/share/keyrings/io.packagecloud.rabbitmq.gpg
RUN echo '\
    deb [signed-by=/usr/share/keyrings/net.launchpad.ppa.rabbitmq.erlang.gpg] http://ppa.launchpad.net/rabbitmq/rabbitmq-erlang/ubuntu focal main\n\
    deb-src [signed-by=/usr/share/keyrings/net.launchpad.ppa.rabbitmq.erlang.gpg] http://ppa.launchpad.net/rabbitmq/rabbitmq-erlang/ubuntu focal main\n\
    deb [signed-by=/usr/share/keyrings/io.packagecloud.rabbitmq.gpg] https://packagecloud.io/rabbitmq/rabbitmq-server/ubuntu/ focal main\n\
    deb-src [signed-by=/usr/share/keyrings/io.packagecloud.rabbitmq.gpg] https://packagecloud.io/rabbitmq/rabbitmq-server/ubuntu/ focal main\n\
' > /etc/apt/sources.list.d/rabbitmq.list
RUN cat /etc/apt/sources.list.d/rabbitmq.list
RUN apt-get update -y
RUN apt-get install -y wget
RUN add-apt-repository ppa:ondrej/php
RUN apt-get update
RUN apt-get -y install openssh-server \
    net-tools \
    zlib1g-dev \
    rsyslog \
    apache2 \
    php7.0 libapache2-mod-php7.0 \
    php7.0-bcmath php7.0-mbstring php7.0-gd php7.0-soap php7.0-zip php7.0-xml php7.0-opcache php7.0-curl php7.0-bz2 php7.0-mcrypt \
    php7.0-ldap \
    php7.0-mysql \
    openssl
RUN mkdir /home/userSpace &&\
    chown www-data:www-data -R /home/userSpace &&\
    mkdir /data &&\
    chown www-data:www-data -R /data &&\
    mkdir /PALogs && chown www-data:www-data -R /PALogs
RUN chmod 777 /tmp
RUN systemctl disable syslog.service
RUN cp /lib/systemd/system/rsyslog.service /etc/systemd/system/rsyslog.service
RUN a2ensite default-ssl; a2enmod ssl
RUN usermod -a -G expedition www-data
RUN sed -i 's/mysqli.reconnect = Off/mysqli.reconnect = On/g' /etc/php/7.0/apache2/php.ini
RUN sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 200M/g' /etc/php/7.0/apache2/php.ini
RUN sed -i 's/post_max_size = 8M/post_max_size = 200M/g' /etc/php/7.0/apache2/php.ini
RUN sed -i 's/mysqli.reconnect = Off/mysqli.reconnect = On/g' /etc/php/7.0/cli/php.ini
RUN sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 200M/g' /etc/php/7.0/cli/php.ini
RUN sed -i 's/post_max_size = 8M/post_max_size = 200M/g' /etc/php/7.0/cli/php.ini

## Begin MariaDB config
RUN groupadd -r mysql && useradd -r -g mysql mysql
RUN set -ex; \
    apt-get update; \
    if ! which gpg; then \
        apt-get install -y --no-install-recommends gnupg; \
    fi;
ENV GOSU_VERSION 1.14
RUN set -eux; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ca-certificates; \
    savedAptMark="$(apt-mark showmanual)"; \
    apt-get install -y --no-install-recommends wget; \
    dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
    wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
    wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
    export GNUPGHOME="$(mktemp -d)"; \
    gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
    gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
    gpgconf --kill all; \
    rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
    apt-mark auto '.*' > /dev/null; \
    [ -z "$savedAptMark" ] || apt-mark manual $savedAptMark > /dev/null; \
    chmod +x /usr/local/bin/gosu; \
    gosu --version; \
    gosu nobody true

RUN mkdir /docker-entrypoint-initdb.d
RUN set -ex; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        libjemalloc2 \
        pwgen \
        xz-utils \
        zstd \
    ;

ARG GPG_KEYS=177F4010FE56CA3336300305F1656F24C74CD1D8
RUN set -ex; \
    export GNUPGHOME="$(mktemp -d)"; \
    for key in $GPG_KEYS; do \
        gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key"; \
    done; \
    gpg --batch --export $GPG_KEYS > /etc/apt/trusted.gpg.d/mariadb.gpg; \
    command -v gpgconf > /dev/null && gpgconf --kill all || :; \
    rm -fr "$GNUPGHOME"; \
    apt-key list

ARG MARIADB_MAJOR=10.6
ENV MARIADB_MAJOR $MARIADB_MAJOR
ARG MARIADB_VERSION=1:10.6.4+maria~focal
ENV MARIADB_VERSION $MARIADB_VERSION
ARG REPOSITORY="https://archive.mariadb.org/mariadb-10.6.4/repo/ubuntu/ focal main"

RUN set -e;\
    echo "deb ${REPOSITORY}" > /etc/apt/sources.list.d/mariadb.list; \
    { \
        echo 'Package: *'; \
        echo 'Pin: release o=MariaDB'; \
        echo 'Pin-Priority: 999'; \
    } > /etc/apt/preferences.d/mariadb

RUN set -ex; \
    { \
        echo "mariadb-server-$MARIADB_MAJOR" mysql-server/root_password password 'unused'; \
        echo "mariadb-server-$MARIADB_MAJOR" mysql-server/root_password_again password 'unused'; \
    } | debconf-set-selections; \
    apt-get update -y; \
    apt-get install -y \
        "mariadb-server=$MARIADB_VERSION" \
        mariadb-backup \
        mariadb-client \
        socat \
    ; \
    rm -rf /var/lib/mysql; \
    mkdir -p /var/lib/mysql /var/run/mysqld; \
    chown -R mysql:mysql /var/lib/mysql /var/run/mysqld; \
    chmod 777 /var/run/mysqld; \
    find /etc/mysql/ -name '*.cnf' -print0 \
        | xargs -0 grep -lZE '^(bind-address|log|user\s)' \
        | xargs -rt -0 sed -Ei 's/^(bind-address|log|user\s)/#&/'; \
    if [ ! -L /etc/mysql/my.cnf ]; then sed -i -e '/includedir/i[mariadb]\nskip-host-cache\nskip-name-resolve\n' /etc/mysql/my.cnf; \
    else sed -i -e '/includedir/ {N;s/\(.*\)\n\(.*\)/[mariadbd]\nskip-host-cache\nskip-name-resolve\n\n\2\n\1/}' \
        /etc/mysql/mariadb.cnf; fi

#RUN filepath=/etc/mysql/mariadb.conf.d/50-server.cnf; \
#    sed -i 's/log_bin/skip-log_bin/g' $filePath; \
#    sed -i 's/bind-address            = 127.0.0.1/#bind-address\t\t= 127.0.0.1/g' $filePath; \
#    echo 'max_allowed_packet  = 64M' >> $filePath; \
#    echo 'binlog_format=mixed' >> $filePath; \
#    echo 'sql_mode = ""' >> $filePath

RUN mysql_install_db

COPY init_mysql.sh /init_mysql.sh
RUN mkdir /build
copy setup/databases.tgz /build/databases.tgz
RUN chmod 755 /init_mysql.sh
RUN /init_mysql.sh

## End MariaDB config

RUN apt-get install -y perl liblist-moreutils-perl python3-pip
RUN pip install lxml; \
    pip install --upgrade pip; \
    pip install unidecode; \
    pip install pandas; \
    pip install six; \
    pip install sqlalchemy

RUN apt-get install -y rabbitmq-server policycoreutils
RUN update-rc.d rabbitmq-server defaults
#RUN /usr/sbin/setsebool httpd_can_network_connect=1

RUN apt-mark hold php-common php-radius php7.0-bcmath php7.0-bz2 php7.0-cli php7.0-common php7.0-curl php7.0-gd \
    php7.0-json php7.0-ldap php7.0-mbstring php7.0-mcrypt php7.0-mysql php7.0-opcache php7.0-readline php7.0-soap \
    php7.0-xml php7.0-zip php7.0 php7.0-common php7.0-radius \
    mariadb-client-10.3 mariadb-client-core-10.3 mariadb-client \
    mariadb-server mariadb-common mariadb-server-10.3 mariadb-server-core-10.3

#RUN wget https://conversionupdates.paloaltonetworks.com/ex-repo.gpg -O /etc/apt/trusted.gpg.d/ex-repo.gpg
RUN apt-get install -y --allow-unauthenticated expedition-beta
COPY init_expedition_python.expect /build/init_expedition_python.expect
RUN expect /build/init_expedition_python.expect
RUN apt-get install -y openjdk-8-jre-headless; \
    apt-get install -y --allow-unauthenticated expeditionml-dependencies-beta
RUN cp /var/www/html/OS/spark/config/log4j.properties /opt/Spark/
RUN rm -f /home/userSpace/environmentParameters.php

RUN cp /var/www/html/OS/startup/panReadOrdersStarter /etc/init.d/panReadOrders; \
    chmod 755 /etc/init.d/panReadOrders; \
    chown root:root /etc/init.d/panReadOrders; \
    ln -s  /etc/init.d/panReadOrders /etc/rc2.d/S99panReadOrders; \
    ln -s  /etc/init.d/panReadOrders /etc/rc3.d/S99panReadOrders; \
    ln -s  /etc/init.d/panReadOrders /etc/rc4.d/S99panReadOrders; \
    ln -s  /etc/init.d/panReadOrders /etc/rc5.d/S99panReadOrders
RUN cp -r /var/lib/mysql /var/lib/mysql.bak
RUN sed -i 's/pip show best-practice-assessment-ngfw-pano/pip show BPA/g' /var/www/html/libs/settings/PackageVersionChecker.php
RUN chown www-data:www-data /var/www
RUN touch /var/log/{auth.log,kern.log,rsyslog.log,syslog}
RUN chown syslog:syslog /var/log/{auth.log,kern.log,rsyslog.log,syslog}
RUN apt-mark hold libmariadbclient18 libmysqlclient18


RUN chmod 755 /root
#COPY ./setup /setup
#WORKDIR /setup
#ENV TERM=xterm
#RUN ./initSetup.sh
WORKDIR /
RUN rm -rf /setup /tmp/* /build
COPY start.sh /
CMD /start.sh
