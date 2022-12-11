FROM debian

RUN apt update -y

RUN apt upgrade -y

RUN apt install -y curl tar build-essential

RUN curl -O https://dl.google.com/go/go1.19.3.linux-amd64.tar.gz

RUN tar -C /usr/local -xzf go1.19.3.linux-amd64.tar.gz

RUN rm go1.19.3.linux-amd64.tar.gz

RUN mkdir app

COPY webapp app

WORKDIR app

ENV USER_DB="forum"
ENV IP_DB="10.102.1.3"
ENV PASSWORD_DB="safeenough"
ENV NAME_DB="forum"

RUN sed -i "s/<USER>/${USER_DB}/g" config.go

RUN sed -i "s/<IP>/${IP_DB}/g" config.go

RUN sed -i "s/<PASSWORD>/${PASSWORD_DB}/g" config.go

RUN sed -i "s/<DATABASE>/${NAME_DB}/g" config.go

RUN /usr/local/go/bin/go build -o forum server/server.go

RUN /usr/local/go/bin/go build -o admin setupadmin/setupadmin.go

RUN rm -r Forum_db.png *.go README.MD go.mod go.sum server setupadmin test 

EXPOSE 8080/tcp

CMD [ "./forum" ]