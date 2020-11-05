#!/bin/bash

source scriptUtils.sh

function createOrg1() {

  infoln "Enroll the CA admin"
  mkdir -p organizations/peerOrganizations/SNM.shahada.ae/

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/SNM.shahada.ae/
  #  rm -rf $FABRIC_CA_CLIENT_HOME/fabric-ca-client-config.yaml
  #  rm -rf $FABRIC_CA_CLIENT_HOME/msp

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:7054 --caname ca-SNM --tls.certfiles ${PWD}/organizations/fabric-ca/SNM/tls-cert.pem
  { set +x; } 2>/dev/null

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-SNM.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-SNM.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-SNM.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-SNM.pem
    OrganizationalUnitIdentifier: orderer' >${PWD}/organizations/peerOrganizations/SNM.shahada.ae/msp/config.yaml

  infoln "Register peer0"
  set -x
  fabric-ca-client register --caname ca-SNM --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles ${PWD}/organizations/fabric-ca/SNM/tls-cert.pem
  { set +x; } 2>/dev/null

  infoln "Register user"
  set -x
  fabric-ca-client register --caname ca-SNM --id.name user1 --id.secret user1pw --id.type client --tls.certfiles ${PWD}/organizations/fabric-ca/SNM/tls-cert.pem
  { set +x; } 2>/dev/null

  infoln "Register the org admin"
  set -x
  fabric-ca-client register --caname ca-SNM --id.name SNMadmin --id.secret SNMadminpw --id.type admin --tls.certfiles ${PWD}/organizations/fabric-ca/SNM/tls-cert.pem
  { set +x; } 2>/dev/null

  mkdir -p organizations/peerOrganizations/SNM.shahada.ae/peers
  mkdir -p organizations/peerOrganizations/SNM.shahada.ae/peers/peer0.SNM.shahada.ae

  infoln "Generate the peer0 msp"
  set -x
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 --caname ca-SNM -M ${PWD}/organizations/peerOrganizations/SNM.shahada.ae/peers/peer0.SNM.shahada.ae/msp --csr.hosts peer0.SNM.shahada.ae --tls.certfiles ${PWD}/organizations/fabric-ca/SNM/tls-cert.pem
  { set +x; } 2>/dev/null

  cp ${PWD}/organizations/peerOrganizations/SNM.shahada.ae/msp/config.yaml ${PWD}/organizations/peerOrganizations/SNM.shahada.ae/peers/peer0.SNM.shahada.ae/msp/config.yaml

  infoln "Generate the peer0-tls certificates"
  set -x
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 --caname ca-SNM -M ${PWD}/organizations/peerOrganizations/SNM.shahada.ae/peers/peer0.SNM.shahada.ae/tls --enrollment.profile tls --csr.hosts peer0.SNM.shahada.ae --csr.hosts localhost --tls.certfiles ${PWD}/organizations/fabric-ca/SNM/tls-cert.pem
  { set +x; } 2>/dev/null

  cp ${PWD}/organizations/peerOrganizations/SNM.shahada.ae/peers/peer0.SNM.shahada.ae/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/SNM.shahada.ae/peers/peer0.SNM.shahada.ae/tls/ca.crt
  cp ${PWD}/organizations/peerOrganizations/SNM.shahada.ae/peers/peer0.SNM.shahada.ae/tls/signcerts/* ${PWD}/organizations/peerOrganizations/SNM.shahada.ae/peers/peer0.SNM.shahada.ae/tls/server.crt
  cp ${PWD}/organizations/peerOrganizations/SNM.shahada.ae/peers/peer0.SNM.shahada.ae/tls/keystore/* ${PWD}/organizations/peerOrganizations/SNM.shahada.ae/peers/peer0.SNM.shahada.ae/tls/server.key

  mkdir -p ${PWD}/organizations/peerOrganizations/SNM.shahada.ae/msp/tlscacerts
  cp ${PWD}/organizations/peerOrganizations/SNM.shahada.ae/peers/peer0.SNM.shahada.ae/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/SNM.shahada.ae/msp/tlscacerts/ca.crt

  mkdir -p ${PWD}/organizations/peerOrganizations/SNM.shahada.ae/tlsca
  cp ${PWD}/organizations/peerOrganizations/SNM.shahada.ae/peers/peer0.SNM.shahada.ae/tls/tlscacerts/* ${PWD}/organizations/peerOrganizations/SNM.shahada.ae/tlsca/tlsca.SNM.shahada.ae-cert.pem

  mkdir -p ${PWD}/organizations/peerOrganizations/SNM.shahada.ae/ca
  cp ${PWD}/organizations/peerOrganizations/SNM.shahada.ae/peers/peer0.SNM.shahada.ae/msp/cacerts/* ${PWD}/organizations/peerOrganizations/SNM.shahada.ae/ca/ca.SNM.shahada.ae-cert.pem

  mkdir -p organizations/peerOrganizations/SNM.shahada.ae/users
  mkdir -p organizations/peerOrganizations/SNM.shahada.ae/users/User1@SNM.shahada.ae

  infoln "Generate the user msp"
  set -x
  fabric-ca-client enroll -u https://user1:user1pw@localhost:7054 --caname ca-SNM -M ${PWD}/organizations/peerOrganizations/SNM.shahada.ae/users/User1@SNM.shahada.ae/msp --tls.certfiles ${PWD}/organizations/fabric-ca/SNM/tls-cert.pem
  { set +x; } 2>/dev/null

  cp ${PWD}/organizations/peerOrganizations/SNM.shahada.ae/msp/config.yaml ${PWD}/organizations/peerOrganizations/SNM.shahada.ae/users/User1@SNM.shahada.ae/msp/config.yaml

  mkdir -p organizations/peerOrganizations/SNM.shahada.ae/users/Admin@SNM.shahada.ae

  infoln "Generate the org admin msp"
  set -x
  fabric-ca-client enroll -u https://SNMadmin:SNMadminpw@localhost:7054 --caname ca-SNM -M ${PWD}/organizations/peerOrganizations/SNM.shahada.ae/users/Admin@SNM.shahada.ae/msp --tls.certfiles ${PWD}/organizations/fabric-ca/SNM/tls-cert.pem
  { set +x; } 2>/dev/null

  cp ${PWD}/organizations/peerOrganizations/SNM.shahada.ae/msp/config.yaml ${PWD}/organizations/peerOrganizations/SNM.shahada.ae/users/Admin@SNM.shahada.ae/msp/config.yaml

}



function createOrderer() {

  infoln "Enroll the CA admin"
  mkdir -p organizations/ordererOrganizations/shahada.ae

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/ordererOrganizations/shahada.ae
  #  rm -rf $FABRIC_CA_CLIENT_HOME/fabric-ca-client-config.yaml
  #  rm -rf $FABRIC_CA_CLIENT_HOME/msp

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:9054 --caname ca-orderer --tls.certfiles ${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem
  { set +x; } 2>/dev/null

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: orderer' >${PWD}/organizations/ordererOrganizations/shahada.ae/msp/config.yaml

  infoln "Register orderer"
  set -x
  fabric-ca-client register --caname ca-orderer --id.name orderer --id.secret ordererpw --id.type orderer --tls.certfiles ${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem
  { set +x; } 2>/dev/null

  infoln "Register the orderer admin"
  set -x
  fabric-ca-client register --caname ca-orderer --id.name ordererAdmin --id.secret ordererAdminpw --id.type admin --tls.certfiles ${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem
  { set +x; } 2>/dev/null

  mkdir -p organizations/ordererOrganizations/shahada.ae/orderers
  mkdir -p organizations/ordererOrganizations/shahada.ae/orderers/shahada.ae

  mkdir -p organizations/ordererOrganizations/shahada.ae/orderers/orderer.shahada.ae
  mkdir -p organizations/ordererOrganizations/shahada.ae/orderers/orderer1.shahada.ae
  mkdir -p organizations/ordererOrganizations/shahada.ae/orderers/orderer2.shahada.ae

  infoln "Generate the orderer msp"
  set -x
  fabric-ca-client enroll -u https://orderer:ordererpw@localhost:9054 --caname ca-orderer -M ${PWD}/organizations/ordererOrganizations/shahada.ae/orderers/orderer.shahada.ae/msp --csr.hosts orderer.shahada.ae --csr.hosts localhost --tls.certfiles ${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem
  { set +x; } 2>/dev/null

  cp ${PWD}/organizations/ordererOrganizations/shahada.ae/msp/config.yaml ${PWD}/organizations/ordererOrganizations/shahada.ae/orderers/orderer.shahada.ae/msp/config.yaml


set -x
  fabric-ca-client enroll -u https://orderer:ordererpw@localhost:9054 --caname ca-orderer -M ${PWD}/organizations/ordererOrganizations/shahada.ae/orderers/orderer1.shahada.ae/msp --csr.hosts orderer1.shahada.ae --csr.hosts localhost --tls.certfiles ${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem
  { set +x; } 2>/dev/null

  cp ${PWD}/organizations/ordererOrganizations/shahada.ae/msp/config.yaml ${PWD}/organizations/ordererOrganizations/shahada.ae/orderers/orderer1.shahada.ae/msp/config.yaml


set -x
  fabric-ca-client enroll -u https://orderer:ordererpw@localhost:9054 --caname ca-orderer -M ${PWD}/organizations/ordererOrganizations/shahada.ae/orderers/orderer2.shahada.ae/msp --csr.hosts orderer2.shahada.ae --csr.hosts localhost --tls.certfiles ${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem
  { set +x; } 2>/dev/null

  cp ${PWD}/organizations/ordererOrganizations/shahada.ae/msp/config.yaml ${PWD}/organizations/ordererOrganizations/shahada.ae/orderers/orderer2.shahada.ae/msp/config.yaml




  infoln "Generate the orderer-tls certificates"
  set -x
  fabric-ca-client enroll -u https://orderer:ordererpw@localhost:9054 --caname ca-orderer -M ${PWD}/organizations/ordererOrganizations/shahada.ae/orderers/orderer.shahada.ae/tls --enrollment.profile tls --csr.hosts orderer.shahada.ae --csr.hosts localhost --tls.certfiles ${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem
  { set +x; } 2>/dev/null

  cp ${PWD}/organizations/ordererOrganizations/shahada.ae/orderers/orderer.shahada.ae/tls/tlscacerts/* ${PWD}/organizations/ordererOrganizations/shahada.ae/orderers/orderer.shahada.ae/tls/ca.crt
  cp ${PWD}/organizations/ordererOrganizations/shahada.ae/orderers/orderer.shahada.ae/tls/signcerts/* ${PWD}/organizations/ordererOrganizations/shahada.ae/orderers/orderer.shahada.ae/tls/server.crt
  cp ${PWD}/organizations/ordererOrganizations/shahada.ae/orderers/orderer.shahada.ae/tls/keystore/* ${PWD}/organizations/ordererOrganizations/shahada.ae/orderers/orderer.shahada.ae/tls/server.key

  mkdir -p ${PWD}/organizations/ordererOrganizations/shahada.ae/orderers/orderer.shahada.ae/msp/tlscacerts
  cp ${PWD}/organizations/ordererOrganizations/shahada.ae/orderers/orderer.shahada.ae/tls/tlscacerts/* ${PWD}/organizations/ordererOrganizations/shahada.ae/orderers/orderer.shahada.ae/msp/tlscacerts/tlsca.shahada.ae-cert.pem

  mkdir -p ${PWD}/organizations/ordererOrganizations/shahada.ae/msp/tlscacerts
  cp ${PWD}/organizations/ordererOrganizations/shahada.ae/orderers/orderer.shahada.ae/tls/tlscacerts/* ${PWD}/organizations/ordererOrganizations/shahada.ae/msp/tlscacerts/tlsca.shahada.ae-cert.pem

  mkdir -p organizations/ordererOrganizations/shahada.ae/users
  mkdir -p organizations/ordererOrganizations/shahada.ae/users/Admin@shahada.ae



   set -x
  fabric-ca-client enroll -u https://orderer:ordererpw@localhost:9054 --caname ca-orderer -M ${PWD}/organizations/ordererOrganizations/shahada.ae/orderers/orderer1.shahada.ae/tls --enrollment.profile tls --csr.hosts orderer1.shahada.ae --csr.hosts localhost --tls.certfiles ${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem
  { set +x; } 2>/dev/null

  cp ${PWD}/organizations/ordererOrganizations/shahada.ae/orderers/orderer1.shahada.ae/tls/tlscacerts/* ${PWD}/organizations/ordererOrganizations/shahada.ae/orderers/orderer1.shahada.ae/tls/ca.crt
  cp ${PWD}/organizations/ordererOrganizations/shahada.ae/orderers/orderer1.shahada.ae/tls/signcerts/* ${PWD}/organizations/ordererOrganizations/shahada.ae/orderers/orderer1.shahada.ae/tls/server.crt
  cp ${PWD}/organizations/ordererOrganizations/shahada.ae/orderers/orderer1.shahada.ae/tls/keystore/* ${PWD}/organizations/ordererOrganizations/shahada.ae/orderers/orderer1.shahada.ae/tls/server.key

  mkdir -p ${PWD}/organizations/ordererOrganizations/shahada.ae/orderers/orderer1.shahada.ae/msp/tlscacerts
  cp ${PWD}/organizations/ordererOrganizations/shahada.ae/orderers/orderer1.shahada.ae/tls/tlscacerts/* ${PWD}/organizations/ordererOrganizations/shahada.ae/orderers/orderer1.shahada.ae/msp/tlscacerts/tlsca.shahada.ae-cert.pem

  mkdir -p ${PWD}/organizations/ordererOrganizations/shahada.ae/msp/tlscacerts
  cp ${PWD}/organizations/ordererOrganizations/shahada.ae/orderers/orderer1.shahada.ae/tls/tlscacerts/* ${PWD}/organizations/ordererOrganizations/shahada.ae/msp/tlscacerts/tlsca.shahada.ae-cert.pem


   set -x
  fabric-ca-client enroll -u https://orderer:ordererpw@localhost:9054 --caname ca-orderer -M ${PWD}/organizations/ordererOrganizations/shahada.ae/orderers/orderer2.shahada.ae/tls --enrollment.profile tls --csr.hosts orderer2.shahada.ae --csr.hosts localhost --tls.certfiles ${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem
  { set +x; } 2>/dev/null

  cp ${PWD}/organizations/ordererOrganizations/shahada.ae/orderers/orderer2.shahada.ae/tls/tlscacerts/* ${PWD}/organizations/ordererOrganizations/shahada.ae/orderers/orderer2.shahada.ae/tls/ca.crt
  cp ${PWD}/organizations/ordererOrganizations/shahada.ae/orderers/orderer2.shahada.ae/tls/signcerts/* ${PWD}/organizations/ordererOrganizations/shahada.ae/orderers/orderer2.shahada.ae/tls/server.crt
  cp ${PWD}/organizations/ordererOrganizations/shahada.ae/orderers/orderer2.shahada.ae/tls/keystore/* ${PWD}/organizations/ordererOrganizations/shahada.ae/orderers/orderer2.shahada.ae/tls/server.key

  mkdir -p ${PWD}/organizations/ordererOrganizations/shahada.ae/orderers/orderer2.shahada.ae/msp/tlscacerts
  cp ${PWD}/organizations/ordererOrganizations/shahada.ae/orderers/orderer2.shahada.ae/tls/tlscacerts/* ${PWD}/organizations/ordererOrganizations/shahada.ae/orderers/orderer2.shahada.ae/msp/tlscacerts/tlsca.shahada.ae-cert.pem

  mkdir -p ${PWD}/organizations/ordererOrganizations/shahada.ae/msp/tlscacerts
  cp ${PWD}/organizations/ordererOrganizations/shahada.ae/orderers/orderer2.shahada.ae/tls/tlscacerts/* ${PWD}/organizations/ordererOrganizations/shahada.ae/msp/tlscacerts/tlsca.shahada.ae-cert.pem




  infoln "Generate the admin msp"
  set -x
  fabric-ca-client enroll -u https://ordererAdmin:ordererAdminpw@localhost:9054 --caname ca-orderer -M ${PWD}/organizations/ordererOrganizations/shahada.ae/users/Admin@shahada.ae/msp --tls.certfiles ${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem
  { set +x; } 2>/dev/null

  cp ${PWD}/organizations/ordererOrganizations/shahada.ae/msp/config.yaml ${PWD}/organizations/ordererOrganizations/shahada.ae/users/Admin@shahada.ae/msp/config.yaml

}
