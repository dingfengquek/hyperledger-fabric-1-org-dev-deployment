# Steps to Start Network

## 1. Pull Docker Images

If required, pull docker images or otherwise ensure they will be available for subsequent steps.

The list of docker images are:

- `hyperledger/fabric-peer:2.3.1`
- `hyperledger/fabric-orderer:2.3.1`
- `hyperledger/fabric-ccenv:2.3.1`
- `hyperledger/fabric-tools:2.3.1`
- `hyperledger/fabric-baseos:2.3.1`
- `hyperledger/fabric-ca:1.4.9`

Note that some images, like `hyperledger/fabric-tools` has no `:latest` tag, so specifying the version number is required.

Also note that LTS Fabric version is 2.2.x.

## 2. Generate Crypto Certs/Materials Using `cryptogen`

Run `./scripts/crypto-gen-run.sh`.

`./scripts/crypto-gen-run.sh` does:

    1. `cryptogen generate --config=./organizations/cryptogen/crypto-config-org1.yaml --output="organizations"`, for org1
    2. `cryptogen generate --config=./organizations/cryptogen/crypto-config-orderer.yaml --output="organizations"`, for orderer

## 3. Start Containers With `docker-compose`

Run `docker-compose -f docker/docker-compose-couch.yaml -f docker/docker-compose-test-net.yaml up`.

## 4. Generate Genesis Block

`FABRIC_CFG_PATH=${PWD}/configtx configtxgen -profile TwoOrgsApplicationGenesis -outputBlock ./channel-artifacts/mychannel1.block -channelID mychannel1`
    1. `FABRIC_CFG_PATH` is used to set the directory where `{dir}/configtx.yaml` will be found.
    2. `configtx` assumes that certs are found in the `MSPDir` specified in `configtx.yaml`, relative to `FABRIC_CFG_PATH`.

## 5. Create Channel

`./scripts/create-channel.sh`

## 6. Start Anchor Peer

`docker exec cli ./scripts/set-anchor-peer.sh`

The script is mounted as a volume into the CLI container (see `docker/docker-compose-test-net.yaml` > `services.cli`).

## 7. What Next?

At this point, the network has been deployed with 1 org and 1 channel with ID `mychannel1`.

Org1 can now compile and chaincode 

# To Remove Everything

1. Run `docker-compose -f docker/docker-compose-couch.yaml -f docker/docker-compose-test-net.yaml down`.
2. To remove ledger state, remove volumes with `docker volume rm docker_orderer.example.com docker_peer0.org1.example.com`.

Optionally, clear generated files in the folder (the ones ignored in `.gitignore`).

# How to Deploy on Kubernetes or OCP

Work in progress

# References

Fabric documentation, tutorials and sample code that this deployment is based can be found at:

- https://hyperledger-fabric.readthedocs.io/en/release-2.2/install.html
- https://github.com/hyperledger/fabric-samples
- https://hyperledger-fabric.readthedocs.io/en/release-2.2/configtx.html
- https://hyperledger-fabric.readthedocs.io/en/release-2.2/deployment_guide_overview.html
- https://hyperledger-fabric.readthedocs.io/en/release-2.2/commands/cryptogen.html
- https://hyperledger-fabric.readthedocs.io/en/latest/membership/membership.html
- https://hyperledger-fabric.readthedocs.io/en/release-2.2/msp.html
