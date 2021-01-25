FROM localregistry:5000/debian:latest

ENV http_proxy="http://193.56.47.20:8080"
ENV https_proxy="http://193.56.47.20:8080"
HEALTHCHECK CMD curl -s http://localhost >/dev/null || exit 1
EXPOSE 80
EXPOSE 443
COPY entrypoint.sh /

RUN apt-get update && \
apt-get -y upgrade && \
apt-get -y install apt-utils gcc make unzip procps libpng-dev libjpeg-dev \
libgd-dev apache2 php snmp libnet-snmp-perl libssl-dev wget bc gawk dc gettext \
libdbi-dev libldap2-dev libmariadbclient-dev libmariadbclient-dev-compat \
dnsutils fping libpqxx-dev ssh libradsec-dev sudo curl

WORKDIR /build

COPY nagios-4.4.6.tar.gz nagios.tar.gz
COPY nagios-plugins-2.3.3.tar.gz nagios-plugins.tar.gz
COPY nrpe-4.0.2.tar.gz nrpe.tar.gz

RUN \
mkdir nagios && \
mkdir nagios-plugins && \
mkdir nrpe && \
tar xf nagios.tar.gz -C nagios --strip-components=1 && \
tar xf nagios-plugins.tar.gz -C nagios-plugins --strip-components=1 && \
tar xf nrpe.tar.gz -C nrpe --strip-components=1

WORKDIR /build/nagios
RUN ./configure --prefix=/nagios && \
make all && \
make install-groups-users && \
make install && \
make install-webconf && \
make install-commandmode && \
make install-config

WORKDIR /build/nagios-plugins
RUN ./configure --prefix=/nagios && \
make && \
make install && \
a2enmod ssl && \
a2enmod cgi && \
a2ensite default-ssl

WORKDIR /build/nrpe
RUN ./configure --prefix=/nagios && \
make check_nrpe && \
make install-plugin

RUN rm -rf /build

ADD sendmail.tar.gz /
RUN \
ln -s /sendmail/phpmail /bin/mail && \
ln -s /sendmail/nagios_host_email /bin/nagios_host_email && \
ln -s /sendmail/nagios_service_email /bin/nagios_service_email

WORKDIR /nagios
RUN mkdir ext-plugins && usermod -a -G nagios www-data
COPY htpasswd.users /nagios/etc/

CMD ["/bin/bash"]

ENTRYPOINT ["/entrypoint.sh"]
