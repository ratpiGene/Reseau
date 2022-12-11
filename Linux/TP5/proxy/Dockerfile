FROM debian

ENV WEB_IP1="10.102.1.2:8080"
ENV WEB_IP2="10.102.1.2:8081"
ENV WEB_IP3="10.102.1.2:8082"
ENV SERVER_NAME="webapp.TP5"

RUN apt update -y

RUN apt upgrade -y

RUN apt install -y openssl nginx

RUN openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 -keyout ${SERVER_NAME}.key -out ${SERVER_NAME}.crt -subj "/C=FR/ST=NA/L=Bordeaux/O=Dis/CN=${SERVER_NAME}"

RUN mv ${SERVER_NAME}.crt /etc/ssl/certs/

RUN mv ${SERVER_NAME}.key /etc/ssl/private/


COPY proxy.template /etc/nginx/template/proxy.template

COPY nginx.template /etc/nginx/template/nginx.template

RUN sed -i "s/<WEB_IP1>/${WEB_IP1}/g" /etc/nginx/template/nginx.template
RUN sed -i "s/<WEB_IP2>/${WEB_IP2}/g" /etc/nginx/template/nginx.template
RUN sed -i "s/<WEB_IP3>/${WEB_IP3}/g" /etc/nginx/template/nginx.template

RUN sed -i "s/<SERVER_NAME>/${SERVER_NAME}/g" /etc/nginx/template/proxy.template

RUN mv /etc/nginx/template/proxy.template /etc/nginx/conf.d/proxy.conf
RUN mv /etc/nginx/template/nginx.template /etc/nginx/nginx.conf

RUN chown www-data:www-data /etc/nginx/conf.d/proxy.conf

RUN chown www-data:www-data /etc/nginx/nginx.conf

RUN chown www-data:www-data /etc/ssl/private/${SERVER_NAME}.key

RUN chown www-data:www-data /etc/ssl/certs/${SERVER_NAME}.crt

RUN chmod 0600 /etc/ssl/private/${SERVER_NAME}.key

EXPOSE 443/tcp

EXPOSE 80/tcp

CMD [ "/usr/sbin/nginx", "-g", "daemon off;" ]