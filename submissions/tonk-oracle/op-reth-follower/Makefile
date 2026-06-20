# ============================================================
# WS-06 Midterm-2 — op-reth follower (client diversity)
# Run an OP-Stack L2 follower with op-reth (Rust EL) + op-node (CL)
# Chain 20260619 · Sequencer "Nova" @ 141.11.156.4
# Tonk Oracle 🌿 (AI · Rule 6) · step-by-step, verified commands
# Usage: make help
# ============================================================
.RECIPEPREFIX = >
.DEFAULT_GOAL := help
SHELL := /bin/bash

# --- config ---
RETHDIR  := $(HOME)/op-stack-build/src/optimism/rust
OPSTACK  := $(HOME)/op-stack
OPRETH   := $(OPSTACK)/op-reth
OPNODE   := $(OPSTACK)/op-node
D        := $(HOME)/my-l2-reth
NOVA_EL  := http://141.11.156.4:9545
NOVA_CL  := http://141.11.156.4:9547
SYNC     := http://141.11.156.4:8181
PEER     := /ip4/141.11.156.4/tcp/9227/p2p/16Uiu2HAkzt25EFAurBMAYJzwExEGKV4aUYkce7aRbEZwUDFmXoao
# ports (all bound to 127.0.0.1 — NEVER 0.0.0.0, fleet rule)
EL_HTTP  := 18880
EL_AUTH  := 18882
EL_P2P   := 18883
CL_RPC   := 18891
CL_P2P   := 18890

.PHONY: help deps build-op-reth fetch-config guard init run-el run-cl up status proof down clean

help: ## list targets
> @grep -E '^[a-z-]+:.*##' $(MAKEFILE_LIST) | sed 's/:.*##/ —/' | sort

deps: ## check toolchain (cargo + clang headers for bindgen)
> @command -v cargo >/dev/null || { echo "need cargo (rustup)"; exit 1; }
> @command -v jq >/dev/null || { echo "need jq"; exit 1; }
> @echo "cargo: $$(cargo --version)"
> @echo "NOTE bindgen needs C headers — if build fails on stdbool.h/stdarg.h, export:"
> @echo '  export LIBCLANG_PATH=/usr/lib/x86_64-linux-gnu'
> @echo '  export BINDGEN_EXTRA_CLANG_ARGS="-I/usr/lib/gcc/x86_64-linux-gnu/13/include -I/usr/include -I/usr/include/x86_64-linux-gnu"'

build-op-reth: ## build op-reth from source (optimism monorepo rust/ workspace)
> @test -x $(OPRETH) && { echo "op-reth already built: $$($(OPRETH) --version|head -1)"; exit 0; } || true
> export LIBCLANG_PATH=/usr/lib/x86_64-linux-gnu; \
> export BINDGEN_EXTRA_CLANG_ARGS="-I/usr/lib/gcc/x86_64-linux-gnu/13/include -I/usr/include -I/usr/include/x86_64-linux-gnu"; \
> cd $(RETHDIR) && cargo build --release -p op-reth && cp target/release/op-reth $(OPRETH)
> @$(OPRETH) --version | head -1

fetch-config: ## download genesis + jwt (:8181) + AUTHORITATIVE rollup (Nova op-node, not stale static)
> mkdir -p $(D)
> curl -s $(SYNC)/genesis.json -o $(D)/genesis.json
> curl -s $(SYNC)/jwt.txt      -o $(D)/jwt.txt
> curl -s -X POST $(NOVA_CL) -H 'Content-Type: application/json' \
>   -d '{"jsonrpc":"2.0","method":"optimism_rollupConfig","params":[],"id":1}' | jq '.result' > $(D)/rollup.json
> @echo "configs ready in $(D)"

guard: ## verify op-reth genesis == rollup l2.hash == Nova live (abort if not — no fake proof)
> @$(OPRETH) init --chain $(D)/genesis.json --datadir $(D) 2>&1 | grep -oiE 'hash=0x[0-9a-f]+' | head -1 | cut -d= -f2 > $(D)/.ghash
> @RG=$$(cat $(D)/.ghash); RJ=$$(jq -r '.genesis.l2.hash' $(D)/rollup.json); \
>  LV=$$(curl -s -X POST $(NOVA_EL) -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["0x0",false],"id":1}' | jq -r '.result.hash'); \
>  echo "op-reth=$$RG"; echo "rollup =$$RJ"; echo "live   =$$LV"; \
>  if [ "$$RG" = "$$RJ" ] && [ "$$RG" = "$$LV" ]; then echo "✅ all consistent"; else echo "❌ ABORT: genesis mismatch"; exit 2; fi

init: fetch-config guard ## fetch + guard + init op-reth db (guard already inits)
> @echo "initialized $(D)"

run-el: ## start op-reth (EL) — bind 127.0.0.1 only
> screen -dmS reth-el bash -c "$(OPRETH) node --chain $(D)/genesis.json --datadir $(D) \
>   --http --http.addr 127.0.0.1 --http.port $(EL_HTTP) --http.api eth,net,web3,debug \
>   --authrpc.addr 127.0.0.1 --authrpc.port $(EL_AUTH) --authrpc.jwtsecret $(D)/jwt.txt \
>   --port $(EL_P2P) --disable-discovery \
>   --rollup.sequencer $(NOVA_EL) --rollup.disable-tx-pool-gossip 2>&1 | tee $(D)/op-reth.log"
> @sleep 8 && echo "op-reth EL up @ 127.0.0.1:$(EL_HTTP) (engine :$(EL_AUTH))"

run-cl: ## start op-node (CL) pointing engine at op-reth
> screen -dmS reth-cl bash -c "$(OPNODE) \
>   --l1=https://ethereum-sepolia-rpc.publicnode.com --l1.beacon=https://ethereum-sepolia-beacon-api.publicnode.com \
>   --l1.trustrpc --l1.rpckind=standard \
>   --l2=http://127.0.0.1:$(EL_AUTH) --l2.jwt-secret=$(D)/jwt.txt --rollup.config=$(D)/rollup.json \
>   --rpc.addr=127.0.0.1 --rpc.port=$(CL_RPC) --p2p.listen.tcp=$(CL_P2P) --p2p.listen.udp=$(CL_P2P) \
>   --p2p.static=$(PEER) --syncmode=consensus-layer --syncmode.req-resp \
>   --l1.rpc-max-batch-size=20 --l1.rpc-rate-limit=20 --log.level=info 2>&1 | tee $(D)/op-node-cl.log"
> @sleep 5 && echo "op-node CL up @ 127.0.0.1:$(CL_RPC)"

up: build-op-reth init run-el run-cl ## full bring-up: build + fetch + guard + init + run EL + CL
> @echo "follower up. 'make status' to watch safe_l2 climb, 'make proof' when safe_l2>0"

status: ## show syncStatus (safe/unsafe/finalized) + EL block
> @curl -s -X POST http://127.0.0.1:$(CL_RPC) -H 'Content-Type: application/json' \
>   -d '{"jsonrpc":"2.0","method":"optimism_syncStatus","params":[],"id":1}' \
>   | jq '{unsafe:.result.unsafe_l2.number, safe:.result.safe_l2.number, finalized:.result.finalized_l2.number, current_l1:.result.current_l1.number}'

proof: ## byte-for-byte head-match vs Nova (op-reth derived blocks)
> @SAFE=$$(curl -s -X POST http://127.0.0.1:$(CL_RPC) -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","method":"optimism_syncStatus","params":[],"id":1}' | jq -r '.result.safe_l2.number'); \
>  echo "safe_l2=$$SAFE — comparing op-reth (:$(EL_HTTP)) vs Nova (:9545):"; \
>  for B in 1 100 300 500 $$((SAFE-5)); do [ $$B -le 0 ] && continue; HX=$$(printf '0x%x' $$B); \
>    M=$$(curl -s -X POST http://127.0.0.1:$(EL_HTTP) -H 'Content-Type: application/json' -d "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getBlockByNumber\",\"params\":[\"$$HX\",false],\"id\":1}" | jq -r '.result.hash // "null"'); \
>    N=$$(curl -s -X POST $(NOVA_EL) -H 'Content-Type: application/json' -d "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getBlockByNumber\",\"params\":[\"$$HX\",false],\"id\":1}" | jq -r '.result.hash // "null"'); \
>    [ "$$M" = "$$N" ] && [ "$$M" != "null" ] && echo "block $$B ✅ $$M" || echo "block $$B ❌ mine=$$M nova=$$N"; done

down: ## stop op-reth + op-node
> @screen -S reth-el -X quit 2>/dev/null; screen -S reth-cl -X quit 2>/dev/null; echo "stopped"

clean: down ## stop + wipe datadir
> @rm -rf $(D); echo "cleaned $(D)"
