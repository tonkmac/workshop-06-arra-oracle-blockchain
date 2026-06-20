# WS-06 Midterm-2 — op-reth HEAD-MATCH PROOF (client diversity) 🌿

Generated 2026-06-20T06:04:09Z · **op-reth (Rust EL) + op-node (CL)** built from source
Proves: a different execution client (Rust op-reth vs Go op-geth) derives the **identical** L2 chain → chain is client-agnostic.

## Genesis — op-reth computes the same hash as op-geth/Nova
```
op-reth init  → 0x1c9445c6cac6880fae00b45dedfc8bf43ce5fd39ec8eb9053b02e2e89a09ff23
Nova live blk0→ 0x1c9445c6cac6880fae00b45dedfc8bf43ce5fd39ec8eb9053b02e2e89a09ff23
✅ identical
```

## Byte-for-byte head-match — op-reth derived (safe_l2=1241) vs Nova :9545
Honest L1-derivation (op-node `--syncmode=consensus-layer`), not a copy.
```
block 1     ✅ 0x3b6a77c5a649e71f47a305bdbc670d11d7470bf6a6d088eae71302d53c677952
block 100   ✅ 0x7e90455bf8f344863ba70498c9a21e592285e6beda1994830970443ce4481341
block 300   ✅ 0xb19e38101e799bc0c9491ed98d4705ec89ff2e38ce77d8b55562951a0fa7fd16
block 500   ✅ 0x426ce40eb2ad3a218bba072b41ba961dfb37c4ed5411e95a3e955d5a614fc928
block 800   ✅ 0xf4e551bf341f0cad7aa54ef13f69be20d914891bc6e1921081709e2b33c064a3
block 1000  ✅ 0x52c9fdf7bba20aaf533be87e23f01d8371541caa5d30725f13ff271ffddd24de
block 1236  ✅ 0xd2076d7f9088facff02c31c5f42a83e17758aff53820b7c48dff0e6356b60266

RESULT: 7/7 byte-for-byte match
```

## Cross-client check: op-reth hashes == op-geth (Midterm-1) hashes
Same block 1/100/300/500 hashes as the op-geth follower in PR #20 → both clients agree byte-for-byte.

## Reproduce
```bash
make build-op-reth   # build op-reth from optimism/rust (with bindgen clang-header env)
make up              # fetch-config + guard + init + run-el (op-reth) + run-cl (op-node)
make status          # watch safe_l2 climb
make proof           # byte-for-byte vs Nova
```
