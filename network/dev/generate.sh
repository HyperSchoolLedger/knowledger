#!/bin/sh
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#
bold=$(tput bold)
normal=$(tput sgr0)

black=$(tput setaf 0)
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blue=$(tput setaf 4)
magenta=$(tput setaf 5)
cyan=$(tput setaf 6)
white=$(tput setaf 7)


export PATH=$GOPATH/src/github.com/hyperledger/fabric/build/bin:${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}

# remove previous crypto material and config transactions
rm -fr config/*
rm -fr crypto-config/*
rm start.sh
rm docker-compose.yaml crypto-config.yaml configtx.yaml

echo "Welcome to Hyperledger crypto generation Script! Please provide some information before generation."
echo ""
echo ""
echo ""
echo "Define a name for channel..."
read CHANNEL_NAME
echo ""
echo ""
echo ""
echo "Define a Hyperledger Orderer Profile name"
read ORDERER_PROFILE_NAME
echo ""
echo ""
echo ""
echo "Define a Hyperledger Channel Profile name"
read CHANNEL_PROFILE_NAME
echo ""
echo ""
echo ""
echo "Define a Hyperledger Organisation name MSP"
read ORG_MSP_NAME
echo ""
echo ""
echo ""
echo "Define a domain"
read ORG_DOMAIN

[ -z "$CHANNEL_NAME"] && {
  echo "You provided an empty channel name. 'mychannel' will be assumed as a default name"
  CHANNEL_NAME="mychannel"
}

[ -z "$ORDERER_PROFILE_NAME"] && {
  echo "You provided an empty channel name. 'OrgOrdererGenesis' will be assumed as a default name"
  ORDERER_PROFILE_NAME="OrgOrdererGenesis"
}

[ -z "$CHANNEL_PROFILE_NAME"] && {
  echo "You provided an empty channel name. 'OrgChannel' will be assumed as a default name"
  CHANNEL_PROFILE_NAME="OrgChannel"
}

[ -z "$ORG_MSP_NAME"] && {
  echo "You provided an empty channel name. 'Org' will be assumed as a default name"
  ORG_MSP_NAME="Org"
}

[ -z "$ORG_DOMAIN"] && {
  echo "You provided an empty channel name. 'example.com' will be assumed as a default domain"
  ORG_DOMAIN=example.com
}

ORG_MSP_NAME_LOWER=`echo $ORG_MSP_NAME | tr '[:upper:]' '[:lower:]'`

cat > crypto-config.yaml << EOF 
OrdererOrgs: 
  - Name: ${ORG_MSP_NAME}
    Domain: $ORG_DOMAIN
    Specs:
      - Hostname: orderer

PeerOrgs:
  - Name: $ORG_MSP_NAME
    Domain: $ORG_MSP_NAME_LOWER.$ORG_DOMAIN
    Template:
      Count: 1
    Users:
      Count: 1
EOF
echo "${blue}crypto-config.yaml generated$normal"

cat > configtx.yaml << EOF
---
Organizations:
    - &OrdererOrg
        Name: OrdererOrg
        ID: OrdererMSP
        MSPDir: crypto-config/ordererOrganizations/$ORG_DOMAIN/msp
    - &Org1
        Name: ${ORG_MSP_NAME}MSP
        ID: ${ORG_MSP_NAME}MSP
        MSPDir: crypto-config/peerOrganizations/$ORG_MSP_NAME_LOWER.$ORG_DOMAIN/msp
        AnchorPeers:
            - Host: peer0.$ORG_MSP_NAME_LOWER.$ORG_DOMAIN
              Port: 7051
Application: &ApplicationDefaults
    Organizations:
Orderer: &OrdererDefaults
    OrdererType: solo
    Addresses:
        - orderer.$ORG_DOMAIN:7050
    BatchTimeout: 2s
    BatchSize:
        MaxMessageCount: 10
        AbsoluteMaxBytes: 99 MB
        PreferredMaxBytes: 512 KB
    Kafka:
        Brokers:
            - 127.0.0.1:9092
    Organizations:

Profiles:
    $ORDERER_PROFILE_NAME:
        Orderer:
            <<: *OrdererDefaults
            Organizations:
                - *OrdererOrg
        Consortiums:
            SampleConsortium:
                Organizations:
                    - *Org1
    $CHANNEL_PROFILE_NAME:
        Consortium: SampleConsortium
        Application:
            <<: *ApplicationDefaults
            Organizations:
                - *Org1
EOF

echo "${blue}configtx.yaml generated$normal"

cat > docker-compose.yaml << EOF
version: '2'

networks:
  basic:

services:
  ca.$ORG_DOMAIN:
    image: hyperledger/fabric-ca
    environment:
      - FABRIC_CA_HOME=/etc/hyperledger/fabric-ca-server
      - FABRIC_CA_SERVER_CA_NAME=ca.$ORG_DOMAIN
      - FABRIC_CA_SERVER_CA_CERTFILE=/etc/hyperledger/fabric-ca-server-config/ca.org1.$ORG_DOMAIN-cert.pem
      - FABRIC_CA_SERVER_CA_KEYFILE=/etc/hyperledger/fabric-ca-server-config/4239aa0dcd76daeeb8ba0cda701851d14504d31aad1b2ddddbac6a57365e497c_sk
    ports:
      - "7054:7054"
    command: sh -c 'fabric-ca-server start -b admin:adminpw'
    volumes:
      - ./crypto-config/peerOrganizations/org1.$ORG_DOMAIN/ca/:/etc/hyperledger/fabric-ca-server-config
    container_name: ca.$ORG_DOMAIN
    networks:
      - basic

  orderer.$ORG_DOMAIN:
    container_name: orderer.$ORG_DOMAIN
    image: hyperledger/fabric-orderer
    environment:
      - ORDERER_GENERAL_LOGLEVEL=info
      - ORDERER_GENERAL_LISTENADDRESS=0.0.0.0
      - ORDERER_GENERAL_GENESISMETHOD=file
      - ORDERER_GENERAL_GENESISFILE=/etc/hyperledger/configtx/genesis.block
      - ORDERER_GENERAL_LOCALMSPID=OrdererMSP
      - ORDERER_GENERAL_LOCALMSPDIR=/etc/hyperledger/msp/orderer/msp
    working_dir: /opt/gopath/src/github.com/hyperledger/fabric/orderer
    command: orderer
    ports:
      - 7050:7050
    volumes:
        - ./config/:/etc/hyperledger/configtx
        - ./crypto-config/ordererOrganizations/$ORG_DOMAIN/orderers/orderer.$ORG_DOMAIN/:/etc/hyperledger/msp/orderer
        - ./crypto-config/peerOrganizations/$ORG_MSP_NAME_LOWER.$ORG_DOMAIN/peers/peer0.$ORG_MSP_NAME_LOWER.$ORG_DOMAIN/:/etc/hyperledger/msp/peerOrg1
    networks:
      - basic

  peer0.$ORG_MSP_NAME_LOWER.$ORG_DOMAIN:
    container_name: peer0.$ORG_MSP_NAME_LOWER.$ORG_DOMAIN
    image: hyperledger/fabric-peer
    environment:
      - CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock
      - CORE_PEER_ID=peer0.$ORG_MSP_NAME_LOWER.$ORG_DOMAIN
      - CORE_LOGGING_PEER=info
      - CORE_CHAINCODE_LOGGING_LEVEL=info
      - CORE_PEER_LOCALMSPID=${ORG_MSP_NAME_LOWER}MSP
      - CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/peer/
      - CORE_PEER_ADDRESS=peer0.$ORG_MSP_NAME_LOWER.$ORG_DOMAIN:7051
      # # the following setting starts chaincode containers on the same
      # # bridge network as the peers
      # # https://docs.docker.com/compose/networking/
      - CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=${COMPOSE_PROJECT_NAME}_basic
      - CORE_LEDGER_STATE_STATEDATABASE=CouchDB
      - CORE_LEDGER_STATE_COUCHDBCONFIG_COUCHDBADDRESS=couchdb:5984
      # The CORE_LEDGER_STATE_COUCHDBCONFIG_USERNAME and CORE_LEDGER_STATE_COUCHDBCONFIG_PASSWORD
      # provide the credentials for ledger to connect to CouchDB.  The username and password must
      # match the username and password set for the associated CouchDB.
      - CORE_LEDGER_STATE_COUCHDBCONFIG_USERNAME=
      - CORE_LEDGER_STATE_COUCHDBCONFIG_PASSWORD=
    working_dir: /opt/gopath/src/github.com/hyperledger/fabric
    command: peer node start
    # command: peer node start --peer-chaincodedev=true
    ports:
      - 7051:7051
      - 7053:7053
    volumes:
        - /var/run/:/host/var/run/
        - ./crypto-config/peerOrganizations/$ORG_MSP_NAME_LOWER.$ORG_DOMAIN/peers/peer0.$ORG_MSP_NAME_LOWER.$ORG_DOMAIN/msp:/etc/hyperledger/msp/peer
        - ./crypto-config/peerOrganizations/$ORG_MSP_NAME_LOWER.$ORG_DOMAIN/users:/etc/hyperledger/msp/users
        - ./config:/etc/hyperledger/configtx
    depends_on:
      - orderer.$ORG_DOMAIN
      - couchdb
    networks:
      - basic

  couchdb:
    container_name: couchdb
    image: hyperledger/fabric-couchdb
    # Populate the COUCHDB_USER and COUCHDB_PASSWORD to set an admin user and password
    # for CouchDB.  This will prevent CouchDB from operating in an "Admin Party" mode.
    environment:
      - COUCHDB_USER=
      - COUCHDB_PASSWORD=
    ports:
      - 5984:5984
    networks:
      - basic

  cli:
    container_name: cli
    image: hyperledger/fabric-tools
    tty: true
    environment:
      - GOPATH=/opt/gopath
      - CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock
      - CORE_LOGGING_LEVEL=info
      - CORE_PEER_ID=cli
      - CORE_PEER_ADDRESS=peer0.$ORG_MSP_NAME_LOWER.$ORG_DOMAIN:7051
      - CORE_PEER_LOCALMSPID=${ORG_MSP_NAME}MSP
      - CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/$ORG_MSP_NAME_LOWER.$ORG_DOMAIN/users/Admin@$ORG_MSP_NAME_LOWER.$ORG_DOMAIN/msp
      - CORE_CHAINCODE_KEEPALIVE=10
    working_dir: /opt/gopath/src/github.com/hyperledger/fabric/peer
    command: /bin/bash
    volumes:
        - /var/run/:/host/var/run/
        - ./../chaincode/:/opt/gopath/src/github.com/
        - ./crypto-config:/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/
    networks:
        - basic
    #depends_on:
    #  - orderer.$ORG_DOMAIN
    #  - peer0.$ORG_MSP_NAME_LOWER.$ORG_DOMAIN
    #  - couchdb
EOF

echo "${blue}docker-compose.yaml generated$normal"

cat > start.sh << EOF
#!/bin/bash
set -ev

# don't rewrite paths for Windows Git Bash users
export MSYS_NO_PATHCONV=1

docker-compose -f docker-compose.yaml down

docker-compose -f docker-compose.yaml up -d ca.$ORG_DOMAIN orderer.$ORG_DOMAIN peer0.$ORG_MSP_NAME_LOWER.$ORG_DOMAIN couchdb

# wait for Hyperledger Fabric to start
# incase of errors when running later commands, issue export FABRIC_START_TIMEOUT=<larger number>
export FABRIC_START_TIMEOUT=10
#echo ${FABRIC_START_TIMEOUT}
sleep 10

# Create the channel
docker exec -e "CORE_PEER_LOCALMSPID=${ORG_MSP_NAME}MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@$ORG_MSP_NAME_LOWER.$ORG_DOMAIN/msp" peer0.$ORG_MSP_NAME_LOWER.$ORG_DOMAIN peer channel create -o orderer.$ORG_DOMAIN:7050 -c $CHANNEL_NAME -f /etc/hyperledger/configtx/channel.tx
# Join peer0.$ORG_MSP_NAME_LOWER.$ORG_DOMAIN to the channel.
docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@$ORG_MSP_NAME_LOWER.$ORG_DOMAIN/msp" peer0.$ORG_MSP_NAME_LOWER.$ORG_DOMAIN peer channel join -b channel.block
EOF

echo "${blue}start script generated$normal"


# generate crypto material
cryptogen generate --config=./crypto-config.yaml
if [ "$?" -ne 0 ]; then
  echo "Failed to generate crypto material..."
  exit 1
fi

# generate genesis block for orderer
configtxgen -profile $ORDERER_PROFILE_NAME -outputBlock ./config/genesis.block
if [ "$?" -ne 0 ]; then
  echo "Failed to generate orderer genesis block..."
  exit 1
fi

# generate channel configuration transaction
configtxgen -profile $CHANNEL_PROFILE_NAME -outputCreateChannelTx ./config/channel.tx -channelID $CHANNEL_NAME
if [ "$?" -ne 0 ]; then
  echo "Failed to generate channel configuration transaction..."
  exit 1
fi

# generate anchor peer transaction
configtxgen -profile $CHANNEL_PROFILE_NAME -outputAnchorPeersUpdate ./config/${ORG_MSP_NAME}MSPanchors.tx -channelID $CHANNEL_NAME -asOrg ${ORG_MSP_NAME}MSP
if [ "$?" -ne 0 ]; then
  echo "Failed to generate anchor peer update for ${ORG_MSP_NAME}MSP..."
  exit 1
fi
