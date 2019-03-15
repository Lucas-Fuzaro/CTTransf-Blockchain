. scripts/crypto.sh
. scripts/setupLogic.sh

echo
echo
echo "o     Removing all pre-existing containers...     "
echo
echo
docker stop $(docker ps -a -q) && docker rm $(docker ps -a -q)
if [ "$?" -ne 0 ]; then
  echo "!!! No dockers running !!!"
fi

echo
echo
echo "o     Removing all pre-existing images...     "
echo
echo
docker rmi $(docker images)
if [ "$?" -ne 0 ]; then
  echo "!!! No images found !!!"
fi
# | grep 'peer0'

# Calling crypto.sh to create Crypto Material
createCrypto

echo
echo
echo "o     Restarting docker-compose network...     "
echo
echo
docker-compose -f docker-compose.yaml down
if [ "$?" -ne 0 ]; then
  echo "!!! No running network !!!"
fi
echo
echo
docker-compose -f docker-compose.yaml up -d
export FABRIC_START_TIMEOUT=50
sleep ${FABRIC_START_TIMEOUT}

# Calling setupLogic.sh for Creating Channel
docker exec cli ./scripts/setupLogic.sh



echo
echo
echo "o     Joining peer0.dealer.com to Channel...     "
echo
echo
docker exec -e "CORE_PEER_LOCALMSPID=DealerMSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@dealer.com/msp" peer0.dealer.com peer channel join -b mychannel.block
verifyResult "$?" "!!! Failed to join peer0.dealer.com !!!"

echo
echo
echo "o     Joining peer1.dealer.com to Channel...     "
echo
echo
docker exec -e "CORE_PEER_LOCALMSPID=DealerMSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@dealer.com/msp" peer1.dealer.com peer channel join -b mychannel.block
verifyResult "$?" "!!! Failed to join peer1.dealer.com !!!"

echo
echo
echo "o     Joining peer0.insurer.com to Channel...     "
echo
echo
docker exec -e "CORE_PEER_LOCALMSPID=InsurerMSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@insurer.com/msp" peer0.insurer.com peer channel join -b mychannel.block
verifyResult "$?" "!!! Failed to join peer0.insurer.com !!!"

echo
echo
echo "o     Joining peer1.insurer.com to Channel...     "
echo
echo
docker exec -e "CORE_PEER_LOCALMSPID=InsurerMSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@insurer.com/msp" peer1.insurer.com peer channel join -b mychannel.block
verifyResult "$?" "!!! Failed to join peer1.insurer.com !!!"

echo
echo
echo "o     Joining peer0.registry.com to Channel...     "
echo
echo
docker exec -e "CORE_PEER_LOCALMSPID=RegistryMSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@registry.com/msp" peer0.registry.com peer channel join -b mychannel.block
verifyResult "$?" "!!! Failed to join peer0.registry.com !!!"

echo
echo
echo "o     Joining peer1.registry.com to Channel...     "
echo
echo
docker exec -e "CORE_PEER_LOCALMSPID=RegistryMSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@registry.com/msp" peer1.registry.com peer channel join -b mychannel.block
verifyResult "$?" "!!! Failed to join peer1.registry.com !!!"

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
