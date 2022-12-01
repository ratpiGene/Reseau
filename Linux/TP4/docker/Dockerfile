FROM debian

RUN apt update -y

RUN apt upgrade -y

RUN apt install -y apache2

COPY index.html /var/www/html/index.html

COPY apache2.conf /etc/apache2/apache2.conf

RUN mkdir /etc/apache2/logs

CMD [ "/usr/sbin/apache2", "-DFOREGROUND" ]

EXPOSE 80/tcp