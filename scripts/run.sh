apt-get update
apt-get install -y lz4 aria2 git sudo
./setup-host.sh
./setup-node.sh -n mainnet -a v0.34.1 -r

# Set constants
SNAP_RPC="https://axelar-rpc.polkachu.com:443"

# Fetch the latest block height and trust hash from the RPC
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height)
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000))
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

# Update the config.toml file with the state sync information
sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.axelar/config/config.toml

wget -O addrbook.json https://snapshots.polkachu.com/addrbook/axelar/addrbook.json --inet4-only
mv addrbook.json $HOME/.axelar/config

PEERS=353f7d0962594bcbfb63c81594e35e39c4c89a1a@18.217.111.172:26656,2362c26b7add662783c5dc26b4c8d153646f825b@3.142.113.84:26656,eeef7f201b6a2b7ebb1af3037bb9022d3dc40372@13.59.129.55:26656,58fbeb88cc00fbb730422f561af0cded7c30dcf6@135.181.142.60:15609,1f34c956e2e36e5eeae1fc4ec6bea65c649c8a02@51.81.49.132:15156
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.axelar/config/config.toml

sed -i.bak -e "s/^chunk_fetchers *=.*/chunk_fetchers = \"16\"/" $HOME/.axelar/config/config.toml

sed -i.bak -e "s/^pruning *=.*/pruning = \"custom\"/" \
           -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"2000\"/" \
	   -e "s/^snapshot-interval *=.*/snapshot-interval = \"2000\"/" \
           -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" \
           -e "s/^pruning-interval *=.*/pruning-interval = \"100\"/" \
           -e "s/^snapshot-keep-recent *=.*/snapshot-keep-recent = \"5\"/" $HOME/.axelar/config/app.toml

/root/.axelar/bin/axelard axelard unsafe-reset-all
/root/.axelar/bin/axelard tendermint unsafe-reset-all --home $HOME/.axelar --keep-addr-book

screen -dmS axelar /root/.axelar/bin/axelard start CANDC --home /root/.axelar

echo "Running axelar in a screen now!"
