FROM golang:latest

WORKDIR /go/src/app

COPY . .

RUN go get github.com/hyperledger/fabric-sdk-go

cmd bash