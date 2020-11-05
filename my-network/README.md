## Running the test network

- **Network Components**:
  
  _orderer.shahada.ae_
  
  _orderer1.shahada.ae_
  
  _orderer2.shahada.ae_
  
  _peer0.SNM.shahada.ae:_




- **Generate crypto files and start docker containers:**

    This will create CA , 1 peer, 3 orderer, 1 couchDB

    Run 
_./network.sh up -ca_

- **Create Channel:**

    Run ./network.sh createChannel -c shchannel




- **Reset the network**

    Run _./network.sh down_
