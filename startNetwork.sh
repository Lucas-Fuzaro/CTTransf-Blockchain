echo
echo
echo "o     Removing all pre-existing containers...     "
echo
echo
docker stop $(docker ps -a -q) && docker rm $(docker ps -a -q)

echo
echo
echo "o     Removing all pre-existing images...     "
echo
echo
docker rmi $(docker images | grep 'peer0')

echo
echo
echo "o     Recreating crypto material...     "
echo
echo
# env NEEDED to create crypto material
export PATH=$PATH:${PWD}/bin
export FABRIC_CFG_PATH=${PWD}
export CHANNEL_NAME=mychannel

# Removing pre-existing crypto material
rm -fr artifacts/*
rm -fr crypto-config/

# Generating Crypto Material
cryptogen generate --config=./crypto-config.yaml
if [ "$?" -ne 0 ]; then
  echo "Failed to generate crypto material..."
  exit 1
fi

# Changing all keys names to key.pem
for file in $(find ./crypto-config/ -iname *_sk); do dir=$(dirname $file); mv ${dir}/*_sk ${dir}/key.pem; done && find ./crypto-config/ -type d | xargs chmod a+rx && find ./crypto-config/ -type f | xargs chmod a+r

# Generating Genesis Block for Orderer
configtxgen -profile OneOrgOrdererGenesis -outputBlock ./artifacts/genesis.block
if [ "$?" -ne 0 ]; then
  echo "Failed to generate Genesis Block..."
  exit 1
fi

# Generating Channel Configuration Transaction
configtxgen -profile OneOrgChannel -outputCreateChannelTx ./artifacts/channel.tx -channelID $CHANNEL_NAME
if [ "$?" -ne 0 ]; then
  echo "Failed to generate channel configuration transaction..."
  exit 1
fi

# Generating Anchor Peer Transaction
configtxgen -profile OneOrgChannel -outputAnchorPeersUpdate ./artifacts/Org1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org1MSP
if [ "$?" -ne 0 ]; then
  echo "Failed to generate Anchor Peer update for Org1MSP..."
  exit 1
fi

echo
echo
echo "o     Restarting docker-compose network...     "
echo
echo
docker-compose -f docker-compose.yaml down
docker-compose -f docker-compose.yaml up -d
export FABRIC_START_TIMEOUT=20
sleep ${FABRIC_START_TIMEOUT}

echo
echo
echo "o     Creating Channel...     "
echo
echo
docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp" peer0.org1.example.com peer channel create -o orderer.example.com:7050 -c $CHANNEL_NAME -f /etc/hyperledger/configtx/channel.tx

echo
echo
echo "o     Joining Peer0.Org1 to Channel...     "
echo
echo
docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp" peer0.org1.example.com peer channel join -b mychannel.block

echo
echo
echo "o     Installing Chaincode...     "
echo
echo
docker exec cliFabric peer chaincode install -n mycc -v 0 -p /opt/gopath/src/github.com -l node

echo
echo
echo "o     Instantiating Chaincode...     "
echo
echo
docker exec cliFabric peer chaincode instantiate -n mycc -v 0 -l node -c '{"Args":[""]}' -C mychannel -P "AND ('Org1MSP.member')"
sleep 10

echo
echo
echo "o     Invoking Chaincode     "
echo "     createCar transaction... "
echo
docker exec cliFabric peer chaincode invoke -n mycc -c '{"function":"createCar","Args":["abc1234", "Black", "Fiat", "Uno", "10000.50", "19000.98", "48507235867", "12345678911"]}' -C mychannel
sleep 2

# echo
# echo
# echo "o     Querying Chaincode...     "
# echo
# echo
# docker exec cliFabric peer chaincode query -n mycc -c '{"function":"queryCar","Args":["abc1234"]}' -C mychannel
# sleep 2

# echo
# echo
# echo "o     offerCar transaction...     "
# echo
# echo
# docker exec cliFabric peer chaincode invoke -n mycc -c '{"function":"offerCar","Args":["abc1234"]}' -C mychannel
# sleep 2

# echo
# echo
# echo "o     Querying Chaincode...     "
# echo
# echo
# docker exec cliFabric peer chaincode query -n mycc -c '{"function":"queryCar","Args":["abc1234"]}' -C mychannel
# sleep 2

# echo
# echo
# echo "o     carInsuranceCheck transaction...     "
# echo
# echo
# docker exec cliFabric peer chaincode invoke -n mycc -c '{"function":"carInsuranceCheck","Args":["abc1234", "{\"status\": \"ok\", \"analysis\": { \"last_owner\": \"joao\", \"current_owner\": \"felipe\", \"payments\":\"all done\"}}"]}' -C mychannel
# sleep 2

# echo
# echo
# echo "o     Querying Chaincode...     "
# echo
# echo
# docker exec cliFabric peer chaincode query -n mycc -c '{"function":"queryCar","Args":["abc1234"]}' -C mychannel
# sleep 2

# echo
# echo
# echo "o     carBackgroundCheck transaction...     "
# echo
# echo
# docker exec cliFabric peer chaincode invoke -n mycc -c '{"function":"carBackgroundCheck","Args":["abc1234", "{\"status\": \"ok\", \"analysis\": { \"last_owner\": \"joao\", \"current_owner\": \"felipe\", \"history\":\"clean\"}}"]}' -C mychannel
# sleep 2

# echo
# echo
# echo "o     Querying Chaincode...     "
# echo
# echo
# docker exec cliFabric peer chaincode query -n mycc -c '{"function":"queryCar","Args":["abc1234"]}' -C mychannel
# sleep 2

# echo
# echo
# echo "o     transferCar transaction...     "
# echo
# echo
# docker exec cliFabric peer chaincode invoke -n mycc -c '{"function":"transferCar","Args":["abc1234"]}' -C mychannel
# sleep 2

# echo
# echo
# echo "o     Querying Chaincode...     "
# echo
# echo
# docker exec cliFabric peer chaincode query -n mycc -c '{"function":"queryCar","Args":["abc1234"]}' -C mychannel
# sleep 2