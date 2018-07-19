FROM golang:latest

WORKDIR /go/src/app

COPY ./api .

RUN curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh

RUN go get -u github.com/gorilla/mux

CMD bash