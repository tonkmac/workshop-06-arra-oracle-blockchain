#!/bin/bash
# WS-06 follower — Tonk's corrected runner (fire when Nova's genesis is LOCKED + consistent)
# Fixes vs workshop sync.sh:
#   - op-node flag: --verbosity (crashes op-node v1.19.0) -> --log.level=info
#   - p2p.static : use Nova's latest announced peer (override stale one in sync.sh)
# Usage: bash sync-fixed.sh   (wipes datadir, re-inits from current :8181 configs)
set -e
BASE=http://141.11.156.4:8181
GETH=~/op-stack/op-geth-binary
NODE=~/op-stack/op-node
DATADIR=~/my-l2-sync
HTTP_PORT=18780; AUTH_PORT=18782; NODE_PORT=18791; P2P_PORT=18790
PEER=/ip4/141.11.156.4/tcp/9227/p2p/16Uiu2HAkzt25EFAurBMAYJzwExEGKV4aUYkce7aRbEZwUDFmXoao

screen -S my-op-geth -X quit 2>/dev/null || true
screen -S my-op-node -X quit 2>/dev/null || true
rm -rf "$DATADIR"; mkdir -p "$DATADIR"

echo '📥 configs...'
curl -s "$BASE/genesis.json" -o "$DATADIR/genesis.json"
curl -s "$BASE/rollup.json"  -o "$DATADIR/rollup.json"
curl -s "$BASE/jwt.txt"      -o "$DATADIR/jwt.txt"

# consistency guard: geth genesis hash must match rollup l2.hash, else abort (don't chase a broken file set)
INITHASH=$($GETH init --datadir "$DATADIR" "$DATADIR/genesis.json" 2>&1 | grep -oP 'Successfully wrote genesis state.*hash=\K[0-9a-f]{6}\.\.[0-9a-f]{6}')
R_FULL=$(jq -r '.genesis.l2.hash' "$DATADIR/rollup.json")
R_SHORT="${R_FULL:2:6}..${R_FULL: -6}"
echo "   geth genesis = $INITHASH   rollup expects = $R_SHORT"
if [ "$INITHASH" != "$R_SHORT" ]; then
  echo "❌ ABORT: genesis.json ≠ rollup.json on server (still inconsistent). Not chasing. Re-run when Nova locks."
  exit 2
fi
echo '   ✅ genesis consistent — starting node'

screen -dmS my-op-geth bash -c "$GETH --datadir=$DATADIR --networkid=20260619 \
  --http --http.addr=127.0.0.1 --http.port=$HTTP_PORT --http.api=eth,net,web3,debug,engine \
  --authrpc.addr=127.0.0.1 --authrpc.port=$AUTH_PORT --authrpc.jwtsecret=$DATADIR/jwt.txt --authrpc.vhosts='*' \
  --nodiscover --syncmode=full --gcmode=full --rollup.disabletxpoolgossip=true \
  --rollup.sequencerhttp=http://141.11.156.4:9545 --verbosity=3 2>&1 | tee $DATADIR/op-geth.log"
sleep 4
screen -dmS my-op-node bash -c "$NODE \
  --l1=https://ethereum-sepolia-rpc.publicnode.com --l1.beacon=https://ethereum-sepolia-beacon-api.publicnode.com \
  --l1.trustrpc --l1.rpckind=standard \
  --l2=http://127.0.0.1:$AUTH_PORT --l2.jwt-secret=$DATADIR/jwt.txt --rollup.config=$DATADIR/rollup.json --l2.enginekind=geth \
  --rpc.addr=127.0.0.1 --rpc.port=$NODE_PORT --p2p.listen.tcp=$P2P_PORT --p2p.listen.udp=$P2P_PORT \
  --p2p.static=$PEER --syncmode=consensus-layer --syncmode.req-resp \
  --l1.rpc-max-batch-size=10 --l1.rpc-rate-limit=10 --log.level=info 2>&1 | tee $DATADIR/op-node.log"
sleep 3
echo '✅ node started. check: optimism_syncStatus @ '$NODE_PORT
