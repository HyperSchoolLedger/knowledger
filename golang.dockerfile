FROM golang:latest

WORKDIR /go/src/app

COPY ./src/test .

RUN curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh

RUN go get -u github.com/hyperledger/fabric-sdk-go \
github.com/cloudflare/cfssl/api \ 
github.com/golang/mock/gomock \
github.com/golang/protobuf/proto \
github.com/mitchellh/mapstructure \
github.com/pkg/errors \
github.com/spf13/cast \
golang.org/x/crypto/ocsp \
google.golang.org/grpc \
github.com/Knetic/govaluate \
github.com/stretchr/testify/assert \
github.com/spf13/viper

CMD bash