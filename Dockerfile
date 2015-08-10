FROM debian:7.8
MAINTAINER Sherman Boyd sherman@seriousmumbo.com

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update
RUN apt-get -y upgrade

RUN groupadd -g 5000 vmail
RUN groupadd -g 5001 mumbo
RUN useradd -r -s /usr/sbin/nologin -g vmail -u 5000 vmail
RUN useradd -r -s /usr/sbin/nologin -g mumbo  -u 5001 mumbo

RUN echo "postfix postfix/mailname string mumbo" | debconf-set-selections
RUN echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections
RUN apt-get install -y -q dovecot-core dovecot-imapd dovecot-lmtpd postfix libsasl2-modules dovecot-sieve ntp dbus

# Generate SSL keys
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/mail.key -out /etc/ssl/certs/mailcert.pem -subj "/C=US/ST=Denial/L=Hi/O=Mom/CN=xyz.mumbo.us"

ADD ./configs/main.cf /etc/postfix/main.cf
ADD ./configs/master.cf /etc/postfix/master.cf
ADD ./configs/dovecot.conf /etc/dovecot/dovecot.conf
RUN chmod 0644 /etc/postfix/main.cf
RUN chmod 0644 /etc/postfix/master.cf
RUN chmod 0644 /etc/dovecot/dovecot.conf
RUN mkdir /maildata
RUN mkdir /maildata/appdata
RUN mkdir /maildata/auth
RUN chown vmail:mumbo /maildata
RUN chmod -R g+rw /maildata

# SASL auth for outgoing relay
RUN echo "dogfood.mumbo.us:587 RLSDZGFPSLASGTRA:EWdZ9kVUwoXx2qagbiefJNWeUt8K9nzlMo6fQfuchvSVyd6yMvEP6R8JkRFj7OZG" > /etc/postfix/sasl_passwd
RUN echo "test.mumbomail.net:587 RLSDZGFPSLASGTRA:EWdZ9kVUwoXx2qagbiefJNWeUt8K9nzlMo6fQfuchvSVyd6yMvEP6R8JkRFj7OZG" >> /etc/postfix/sasl_passwd
RUN postmap /etc/postfix/sasl_passwd

RUN apt-get -y -q autoclean
RUN apt-get -y -q autoremove
RUN apt-get clean

EXPOSE 25
EXPOSE 143
EXPOSE 587

ENTRYPOINT service postfix start; dovecot -F