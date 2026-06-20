#!/bin/bash
# WS-06 — fire a REAL head-match proof using Nova's AUTHORITATIVE rollup config
# (bypasses the stale :8181/rollup.json by pulling optimism_rollupConfig from Nova's op-node)
set -e
GETH=~/op-stack/op-geth-binary
NODE=~/op-stack/op-node
DATADIR=~/my-l2-sync
HTTP_PORT=18780; AUTH_PORT=18782; NODE_PORT=18791; P2P_PORT=18790
NOVA_EL=http://141.11.156.4:9545
NOVA_CL=http://141.11.156.4:9547
PEER=/ip4/141.11.156.4/tcp/9227/p2p/16Uiu2HAkzt25EFAurBMAYJzwExEGKV4aUYkce7aRbEZwUDFmXoao

screen -S my-op-geth -X quit 2>/dev/null || true
screen -S my-op-node -X quit 2>/dev/null || true
rm -rf "$DATADIR"; mkdir -p "$DATADIR"

echo '📥 genesis.json + jwt from :8181, rollup from Nova authoritative RPC...'
curl -s http://141.11.156.4:8181/genesis.json -o "$DATADIR/genesis.json"
curl -s http://141.11.156.4:8181/jwt.txt      -o "$DATADIR/jwt.txt"
curl -s -X POST "$NOVA_CL" -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","method":"optimism_rollupConfig","params":[],"id":1}' | jq '.result' > "$DATADIR/rollup.json"

# consistency guard vs LIVE: geth genesis hash must equal Nova rollup l2.hash AND Nova live block0
INITHASH=$($GETH init --datadir "$DATADIR" "$DATADIR/genesis.json" 2>&1 | grep -oP 'Successfully wrote genesis state.*hash=\K[0-9a-f]{6}\.\.[0-9a-f]{6}')
R_FULL=$(jq -r '.genesis.l2.hash' "$DATADIR/rollup.json"); R_SHORT="${R_FULL:2:6}..${R_FULL: -6}"
LIVE_FULL=$(curl -s -X POST "$NOVA_EL" -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["0x0",false],"id":1}' | jq -r '.result.hash'); LIVE_SHORT="${LIVE_FULL:2:6}..${LIVE_FULL: -6}"
echo "   geth=$INITHASH  rollup=$R_SHORT  live=$LIVE_SHORT"
if [ "$INITHASH" != "$R_SHORT" ] || [ "$INITHASH" != "$LIVE_SHORT" ]; then
  echo "❌ ABORT: genesis/rollup/live not all equal. Not firing."; exit 2
fi
echo '   ✅ genesis == rollup == Nova live — all three consistent. Firing.'

screen -dmS my-op-geth bash -c "$GETH --datadir=$DATADIR --networkid=20260619 \
  --http --http.addr=127.0.0.1 --http.port=$HTTP_PORT --http.api=eth,net,web3,debug,engine \
  --authrpc.addr=127.0.0.1 --authrpc.port=$AUTH_PORT --authrpc.jwtsecret=$DATADIR/jwt.txt --authrpc.vhosts='*' \
  --nodiscover --syncmode=full --gcmode=full --rollup.disabletxpoolgossip=true \
  --rollup.sequencerhttp=$NOVA_EL --verbosity=3 2>&1 | tee $DATADIR/op-geth.log"
sleep 4
screen -dmS my-op-node bash -c "$NODE \
  --l1=https://ethereum-sepolia-rpc.publicnode.com --l1.beacon=https://ethereum-sepolia-beacon-api.publicnode.com \
  --l1.trustrpc --l1.rpckind=standard \
  --l2=http://127.0.0.1:$AUTH_PORT --l2.jwt-secret=$DATADIR/jwt.txt --rollup.config=$DATADIR/rollup.json --l2.enginekind=geth \
  --rpc.addr=127.0.0.1 --rpc.port=$NODE_PORT --p2p.listen.tcp=$P2P_PORT --p2p.listen.udp=$P2P_PORT \
  --p2p.static=$PEER --syncmode=consensus-layer --syncmode.req-resp \
  --l1.rpc-max-batch-size=20 --l1.rpc-rate-limit=20 --log.level=info 2>&1 | tee $DATADIR/op-node.log"
sleep 3
echo "✅ fired. genesis = $LIVE_FULL (== Nova live). polling safe_l2 next."
