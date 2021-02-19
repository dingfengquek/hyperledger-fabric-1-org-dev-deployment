#!/bin/bash

export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=peer0.org1.example.com:7051

ORDERER_CA=${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
CHANNEL_NAME=mychannel1

CHANNEL_CONFIG_BLOCK_FILENAME=config_block.pb

peer channel fetch config ${CHANNEL_CONFIG_BLOCK_FILENAME} \
    -o orderer.example.com:7050 \
    --ordererTLSHostnameOverride orderer.example.com \
    -c ${CHANNEL_NAME} \
    --tls \
    --cafile ${ORDERER_CA}

configtxlator proto_decode --input ${CHANNEL_CONFIG_BLOCK_FILENAME} --type common.Block | jq .data.data[0].payload.data.config > ${CORE_PEER_LOCALMSPID}_config.json

HOST="peer0.org1.example.com"
PORT=7051

jq '.channel_group.groups.Application.groups.'${CORE_PEER_LOCALMSPID}'.values += {"AnchorPeers":{"mod_policy": "Admins","value":{"anchor_peers": [{"host": "'$HOST'","port": '$PORT'}]},"version": "0"}}' ${CORE_PEER_LOCALMSPID}_config.json > ${CORE_PEER_LOCALMSPID}_modified_config.json

configtxlator proto_encode --input "${CORE_PEER_LOCALMSPID}_config.json" --type common.Config > original_config.pb
configtxlator proto_encode --input "${CORE_PEER_LOCALMSPID}_modified_config.json" --type common.Config > modified_config.pb
configtxlator compute_update --channel_id ${CHANNEL_NAME} --original original_config.pb --updated modified_config.pb > config_update.pb
configtxlator proto_decode --input config_update.pb --type common.ConfigUpdate > config_update.json
echo '{"payload":{"header":{"channel_header":{"channel_id":"'${CHANNEL_NAME}'", "type":2}},"data":{"config_update":'$(cat config_update.json)'}}}' | jq . > config_update_in_envelope.json
configtxlator proto_encode --input config_update_in_envelope.json --type common.Envelope > "${CORE_PEER_LOCALMSPID}_anchors.tx"

peer channel update \
    -o orderer.example.com:7050 \
    --ordererTLSHostnameOverride orderer.example.com \
    -f ${CORE_PEER_LOCALMSPID}_anchors.tx \
    --tls \
    --cafile "${ORDERER_CA}" \
    -c ${CHANNEL_NAME}

