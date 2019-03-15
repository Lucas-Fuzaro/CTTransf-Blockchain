CHANNEL_NAME="main-channel"

createCrypto() {
    echo
    echo
    echo "o     Setting all necessary ENV variables...     "
    echo
    echo
    # env NEEDED to create crypto material
    export PATH=$PATH:${PWD}/../bin
    export FABRIC_CFG_PATH=${PWD}/../blockchain-config/
    cd ..

    echo
    echo
    echo "o     Generating Crypto Material...     "
    echo
    echo
    echo "@@@ Removing pre-existing crypto material... @@@"
    echo
    rm -rf artifacts
    rm -rf crypto-config
    if [ "$?" -ne 0 ]; then
        echo "!!! Crypto material not found !!!"
    fi

    echo
    echo "@@@ Recreating Artifacts repo... @@@"
    echo
    mkdir artifacts

    echo
    echo "@@@ Creating Crypto Material... @@@"
    echo
    cryptogen generate --config=./blockchain-config/crypto-config.yaml
    if [ "$?" -ne 0 ]; then
        echo "!!! Failed to generate crypto material !!!"
        exit 1
    fi

    echo
    echo "@@@ Changing all keys names to key.pem... @@@"
    echo
    for file in $(find ./crypto-config/ -iname *_sk); do
        dir=$(dirname $file) mv ${dir}/*_sk ${dir}/key.pem
    done && find ./crypto-config/ -type d | xargs chmod a+rx && find ./crypto-config/ -type f | xargs chmod a+r
    if [ "$?" -ne 0 ]; then
        echo "!!! Failed to find the keys !!!"
        exit 1
    fi

    echo
    echo "@@@ Generating Genesis Block for Orderer... @@@"
    echo
    configtxgen -profile ThreeOrgsOrdererGenesis -outputBlock ./artifacts/genesis.block
    if [ "$?" -ne 0 ]; then
        echo "!!! Failed to generate Genesis Block !!!"
        exit 1
    fi

    echo
    echo "@@@ Generating Channel Configuration Transaction... @@@"
    echo
    configtxgen -profile ThreeOrgsChannel -outputCreateChannelTx ./artifacts/${CHANNEL_NAME}.tx -channelID $CHANNEL_NAME
    if [ "$?" -ne 0 ]; then
        echo "!!! Failed to generate channel configuration transaction !!!"
        exit 1
    fi

    echo
    echo "@@@ Generating DealerMSP Anchor Peer Transaction... @@@"
    echo
    configtxgen -profile ThreeOrgsChannel -outputAnchorPeersUpdate ./artifacts/DealerMSPanchors.tx -channelID $CHANNEL_NAME -asOrg DealerMSP
    if [ "$?" -ne 0 ]; then
        echo "!!! Failed to generate Anchor Peer update for DealerMSP !!!"
        exit 1
    fi

    echo
    echo "@@@ Generating InsurerMSP Anchor Peer Transaction... @@@"
    echo
    configtxgen -profile ThreeOrgsChannel -outputAnchorPeersUpdate ./artifacts/InsurerMSPanchors.tx -channelID $CHANNEL_NAME -asOrg InsurerMSP
    if [ "$?" -ne 0 ]; then
        echo "!!! Failed to generate Anchor Peer update for InsurerMSP !!!"
        exit 1
    fi
    echo
    echo "@@@ Generating RegistryMSP Anchor Peer Transaction... @@@"
    echo
    configtxgen -profile ThreeOrgsChannel -outputAnchorPeersUpdate ./artifacts/RegistryMSPanchors.tx -channelID $CHANNEL_NAME -asOrg RegistryMSP
    if [ "$?" -ne 0 ]; then
        echo "!!! Failed to generate Anchor Peer update for RegistryMSP !!!"
        exit 1
    fi
}
