PEER_CA=/FABRIC-PEER/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations
CLI_ROOT=/opt/gopath/src/github.com/hyperledger/fabric/peer/
CHANNEL_NAME="main-channel"
ORDERER_URL="orderer0.cttransf.com:7050"
RETRY=0

verifyResult() {
  if [ $1 -ne 0 ]; then
    echo "!!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
    echo
    exit 1
  fi
}

setEnv() {
  PEER=$1
  ORG=$2

  CORE_PEER_TLS_ROOTCERT_FILE=${PEER_CA}/${ORG}/peers/${PEER}.${ORG}/tls/ca.crt
  CORE_PEER_MSPCONFIGPATH=${PEER_CA}/${ORG}/users

  if [ $ORG = "dealer.com" ]; then
    CORE_PEER_LOCALMSPID="DealerMSP"

  elif [ $ORG = "insurer.com" ]; then
    CORE_PEER_LOCALMSPID="InsurerMSP"

  elif [ $ORG = "registry.com" ]; then
    CORE_PEER_LOCALMSPID="RegistryMSP"
  else
    echo "==== NOT A VALID ORG! ===="
    exit 1
  fi

}

createChannel() {
  echo
  echo
  echo "o     Creating Channel...     "
  echo
  echo
  peer channel create -o $ORDERER_URL -c $CHANNEL_NAME -f ${CLI_ROOT}/artifacts/${CHANNEL_NAME}.tx
  verifyResult "$?" "!!! Channel creation failed !!!"
}

joinPeers() {
  PEER=$1
  ORG=$2

  setEnv $PEER $ORG

  peer channel join -b ${CHANNEL_NAME}.block
  if [ "$?" -ne 0]; then
    RETRY=$(expr $RETRY + 1)
    echo "${PEER}.${ORG} failed to join the channel. Retrying in 10 seconds..."
    sleep 10
    joinPeers $PEER $ORG
  elif [ "$?" -ne 0 ] && [ $RETRY -eq 5]; then
    echo "${PEER}.${ORG} failed to join the channel too many times. Stopping retry loop..."
    exit 1
  else
    RETRY=0
  fi

}

updateAnchors() {
  PEER=$1
  ORG=$2

  setEnv $PEER $ORG
}
