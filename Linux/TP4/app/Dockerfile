FROM debian

RUN apt update -y

RUN apt upgrade -y

RUN apt install -y curl tar build-essential

RUN curl -O https://dl.google.com/go/go1.19.3.linux-amd64.tar.gz

RUN tar -C /usr/local -xzf go1.19.3.linux-amd64.tar.gz

RUN rm go1.19.3.linux-amd64.tar.gz

RUN mkdir app

COPY forum app

WORKDIR app

RUN /usr/local/go/bin/go build -o forum server/server.go

RUN /usr/local/go/bin/go build -o admin setupadmin/setupadmin.go

RUN rm -r Forum_db.png *.go README.MD go.mod go.sum server setupadmin test 

CMD [ "./goforum" ]

EXPOSE 8080/tcp