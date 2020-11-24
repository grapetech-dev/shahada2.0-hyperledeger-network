#!/usr/bin/env bash

#export PATH=${PWD}/../bin:$PATH

OS_ARCH=$(echo "$(uname -s | tr '[:upper:]' '[:lower:]' | sed 's/mingw64_nt.*/windows/')-$(uname -m | sed 's/x86_64/amd64/g')" | awk '{print tolower($0)}')

export PATH=${PWD}/../${OS_ARCH}:$PATH


export FABRIC_CFG_PATH=${PWD}/configtx
export VERBOSE=false
export COMPOSE_FILE_BASE=docker/docker-compose-test-net.yaml
export COMPOSE_FILE_COUCH=docker/docker-compose-couch.yaml
export COMPOSE_FILE_CA=docker/docker-compose-ca.yaml


function networkDown() {
  # stop org3 containers also in addition to org1 and org2, in case we were running sample to add org3
  docker-compose -f $COMPOSE_FILE_BASE -f $COMPOSE_FILE_COUCH -f $COMPOSE_FILE_CA down --volumes --remove-orphans
  # Don't remove the generated artifacts -- note, the ledgers are always removed

    # Bring down the network, deleting the volumes
    #Cleanup the chaincode containers
    clearContainers
    #Cleanup images
    removeUnwantedImages


    if [ -d "organizations/peerOrganizations" ]; then
    rm -Rf organizations/peerOrganizations && rm -Rf organizations/ordererOrganizations
  fi

    # remove orderer block and other channel configuration transactions and certs
    docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf system-genesis-block/*.block organizations/peerOrganizations organizations/ordererOrganizations'
    ## remove fabric ca artifacts
    docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf organizations/fabric-ca/org1/msp organizations/fabric-ca/org1/tls-cert.pem organizations/fabric-ca/org1/ca-cert.pem organizations/fabric-ca/org1/IssuerPublicKey organizations/fabric-ca/org1/IssuerRevocationPublicKey organizations/fabric-ca/org1/fabric-ca-server.db'
    docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf organizations/fabric-ca/org2/msp organizations/fabric-ca/org2/tls-cert.pem organizations/fabric-ca/org2/ca-cert.pem organizations/fabric-ca/org2/IssuerPublicKey organizations/fabric-ca/org2/IssuerRevocationPublicKey organizations/fabric-ca/org2/fabric-ca-server.db'
    docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf organizations/fabric-ca/ordererOrg/msp organizations/fabric-ca/ordererOrg/tls-cert.pem organizations/fabric-ca/ordererOrg/ca-cert.pem organizations/fabric-ca/ordererOrg/IssuerPublicKey organizations/fabric-ca/ordererOrg/IssuerRevocationPublicKey organizations/fabric-ca/ordererOrg/fabric-ca-server.db'
    docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf addOrg3/fabric-ca/org3/msp addOrg3/fabric-ca/org3/tls-cert.pem addOrg3/fabric-ca/org3/ca-cert.pem addOrg3/fabric-ca/org3/IssuerPublicKey addOrg3/fabric-ca/org3/IssuerRevocationPublicKey addOrg3/fabric-ca/org3/fabric-ca-server.db'
    # remove channel and script artifacts
    docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf channel-artifacts log.txt *.tar.gz'


}

function clearContainers() {
  CONTAINER_IDS=$(docker ps -a | awk '($2 ~ /dev-peer.*/) {print $1}')
  if [ -z "$CONTAINER_IDS" -o "$CONTAINER_IDS" == " " ]; then
    echo "No containers available for deletion"
  else
    docker rm -f $CONTAINER_IDS
  fi
}

function removeUnwantedImages() {
  DOCKER_IMAGE_IDS=$(docker images | awk '($1 ~ /dev-peer.*/) {print $3}')
  if [ -z "$DOCKER_IMAGE_IDS" -o "$DOCKER_IMAGE_IDS" == " " ]; then
    echo "No images available for deletion"
  else
    docker rmi -f $DOCKER_IMAGE_IDS
  fi
}

networkDown



IMAGE_TAG=latest docker-compose -f $COMPOSE_FILE_CA up -d 2>&1

    . organizations/fabric-ca/registerEnroll.sh

 sleep 5

  echo "Create Org1 Identities"

    createOrg1

    echo "Create Org2 Identities"

    createOrg2

    echo "Create Orderer Org Identities"

#    createOrderer

   set -x
    cryptogen generate --config=./organizations/cryptogen/crypto-config-orderer.yaml --output="organizations"
    res=$?
    { set +x; } 2>/dev/null


  echo "Generate CCP files for Org1 and Org2"
  ./organizations/ccp-generate.sh


 echo "Generating Orderer Genesis block"

  configtxgen -profile TwoOrgsOrdererGenesis -channelID system-channel -outputBlock ./system-genesis-block/genesis.block



COMPOSE_FILES="-f ${COMPOSE_FILE_BASE}"
COMPOSE_FILES="${COMPOSE_FILES} -f ${COMPOSE_FILE_COUCH}"


IMAGE_TAG=latest docker-compose ${COMPOSE_FILES} up -d 2>&1



CHANNEL_NAME="mychannel"
DELAY="3"
MAX_RETRY="5"
VERBOSE="false"


configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/${CHANNEL_NAME}.tx -channelID $CHANNEL_NAME

configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/SNMMSPanchors.tx -channelID $CHANNEL_NAME -asOrg SNMMSP

configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/SUMSPanchors.tx -channelID $CHANNEL_NAME -asOrg SUMSP

export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/shahada.ae/orderers/orderer.shahada.ae/msp/tlscacerts/tlsca.shahada.ae-cert.pem
export PEER0_ORG1_CA=${PWD}/organizations/peerOrganizations/org1.shahada.ae/peers/peer0.org1.shahada.ae/tls/ca.crt
export PEER0_ORG2_CA=${PWD}/organizations/peerOrganizations/org2.shahada.ae/peers/peer0.org2.shahada.ae/tls/ca.crt



FABRIC_CFG_PATH=$PWD/../config/

    export CORE_PEER_LOCALMSPID="SNMMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG1_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.shahada.ae/users/Admin@org1.shahada.ae/msp
    export CORE_PEER_ADDRESS=localhost:7051

set -x
peer channel create -o localhost:7050 -c $CHANNEL_NAME --ordererTLSHostnameOverride orderer.shahada.ae -f ./channel-artifacts/${CHANNEL_NAME}.tx --outputBlock ./channel-artifacts/${CHANNEL_NAME}.block --tls --cafile $ORDERER_CA >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt

    export CORE_PEER_LOCALMSPID="SNMMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG1_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.shahada.ae/users/Admin@org1.shahada.ae/msp
    export CORE_PEER_ADDRESS=localhost:7051

set -x
peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt

    export CORE_PEER_LOCALMSPID="SUMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG2_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org2.shahada.ae/users/Admin@org2.shahada.ae/msp
    export CORE_PEER_ADDRESS=localhost:9051

set -x
peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt

  export CORE_PEER_LOCALMSPID="SNMMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG1_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.shahada.ae/users/Admin@org1.shahada.ae/msp
    export CORE_PEER_ADDRESS=localhost:7051

set -x
peer channel update -o localhost:7050 --ordererTLSHostnameOverride orderer.shahada.ae -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx --tls --cafile $ORDERER_CA >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt

 export CORE_PEER_LOCALMSPID="SUMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG2_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org2.shahada.ae/users/Admin@org2.shahada.ae/msp
    export CORE_PEER_ADDRESS=localhost:9051

set -x
peer channel update -o localhost:7050 --ordererTLSHostnameOverride orderer.shahada.ae -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx --tls --cafile $ORDERER_CA >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt




FABRIC_CFG_PATH=$PWD/../config/

CC_NAME="basic"
CC_VERSION="1.0"
CC_SEQUENCE="1"
CC_SRC_PATH="../asset-transfer-basic/chaincode-javascript"
CC_RUNTIME_LANGUAGE="node"
INIT_REQUIRED=""
CC_END_POLICY=""
CC_COLL_CONFIG=""
PEER_CONN_PARMS=" --peerAddresses localhost:7051  --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org1.shahada.ae/peers/peer0.org1.shahada.ae/tls/ca.crt   --peerAddresses localhost:9051 --tlsRootCertFiles  ${PWD}/organizations/peerOrganizations/org2.shahada.ae/peers/peer0.org2.shahada.ae/tls/ca.crt "


  export CORE_PEER_LOCALMSPID="SNMMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG1_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.shahada.ae/users/Admin@org1.shahada.ae/msp
    export CORE_PEER_ADDRESS=localhost:7051
set -x
peer lifecycle chaincode package ${CC_NAME}.tar.gz --path ${CC_SRC_PATH} --lang ${CC_RUNTIME_LANGUAGE} --label ${CC_NAME}_${CC_VERSION} >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt

set -x
peer lifecycle chaincode install ${CC_NAME}.tar.gz >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt

export CORE_PEER_LOCALMSPID="SUMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG2_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org2.shahada.ae/users/Admin@org2.shahada.ae/msp
    export CORE_PEER_ADDRESS=localhost:9051

set -x
peer lifecycle chaincode install ${CC_NAME}.tar.gz >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt


  export CORE_PEER_LOCALMSPID="SNMMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG1_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.shahada.ae/users/Admin@org1.shahada.ae/msp
    export CORE_PEER_ADDRESS=localhost:7051

  set -x
  peer lifecycle chaincode queryinstalled >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  PACKAGE_ID=$(sed -n "/${CC_NAME}_${CC_VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)


  set -x
  peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.shahada.ae --tls --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${CC_VERSION} --package-id ${PACKAGE_ID} --sequence ${CC_SEQUENCE} ${INIT_REQUIRED} ${CC_END_POLICY} ${CC_COLL_CONFIG} >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt

    export CORE_PEER_LOCALMSPID="SUMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG2_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org2.shahada.ae/users/Admin@org2.shahada.ae/msp
    export CORE_PEER_ADDRESS=localhost:9051

  set -x
  peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.shahada.ae --tls --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${CC_VERSION} --package-id ${PACKAGE_ID} --sequence ${CC_SEQUENCE} ${INIT_REQUIRED} ${CC_END_POLICY} ${CC_COLL_CONFIG} >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt


  export CORE_PEER_LOCALMSPID="SNMMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG1_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.shahada.ae/users/Admin@org1.shahada.ae/msp
    export CORE_PEER_ADDRESS=localhost:7051

  set -x
  peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.shahada.ae --tls --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME} $PEER_CONN_PARMS --version ${CC_VERSION} --sequence ${CC_SEQUENCE} ${INIT_REQUIRED} ${CC_END_POLICY} ${CC_COLL_CONFIG} >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
