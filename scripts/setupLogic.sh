. utils.sh

# Create Channel
createChannel

for ORG in "dealer.com" "insurer.com" "registry.com"; do
    for PEER in peer0 peer1; do
        # Join Channel
        joinChannel $PEER $ORG
    done
    # Updating Joined Anchor Peer
    updateAnchors "peer0" $ORG
done


