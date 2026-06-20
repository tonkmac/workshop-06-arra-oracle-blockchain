# WS-06 Midterm-2 — op-reth follower (client diversity) 🌿

รัน follower ของ chain 20260619 ด้วย **op-reth (Rust EL)** แทน op-geth (Go) — พิสูจน์ว่า L2 chain เดียวกัน
derive ได้จากคนละ execution client แบบ byte-for-byte = **chain client-agnostic จริง**

— Tonk Oracle (AI · Rule 6) · design: [Issue #26](https://github.com/the-oracle-keeps-the-human-human/workshop-06-arra-oracle-blockchain/issues/26)

## ผล (proof)
- ✅ op-reth (Rust) init genesis → `0x1c9445c6` = ตรงกับ op-geth/Nova เป๊ะ
- ✅ **head-match 7/7 byte-for-byte** vs Nova (safe_l2 derive จาก L1) — ดู [`HEAD-MATCH-PROOF-reth.md`](HEAD-MATCH-PROOF-reth.md)
- ✅ hash ตรงกับ op-geth follower (Midterm-1, PR #20) ทุก block → 2 client เห็นตรงกัน

## ใช้งาน (Makefile step-by-step)
```bash
make help            # list targets
make build-op-reth   # build op-reth จาก optimism/rust workspace (มี bindgen env fix)
make up              # build + fetch-config + guard + run op-reth(EL) + op-node(CL)
make status          # ดู safe_l2 / unsafe_l2 / finalized
make proof           # byte-for-byte head-match vs Nova
make down / make clean
```

## สถาปัตยกรรม
```
L1 Sepolia ─(batch)→ op-node (CL, v1.19.0) ─engine→ op-reth (EL, Rust)
                     derive safe/unsafe          เก็บ state + รัน EVM
```
op-node (CL) ใช้ตัวเดิมจาก Midterm-1 — consensus layer ไม่ผูกกับ EL client = เปลี่ยน EL ได้เลย

## Pitfalls ที่เจอ (เขียนไว้ให้คนต่อไป)
1. **op-reth ย้าย repo** — reth v2.3.0 ไม่มีแล้ว ย้ายไป `ethereum-optimism/optimism/rust/op-reth` (build: `cargo build --release -p op-reth`)
2. **bindgen หา C headers ไม่เจอ** (`stdbool.h`/`stdarg.h`) — ไม่มี clang binary/resource headers → ชี้ไป gcc:
   ```bash
   export LIBCLANG_PATH=/usr/lib/x86_64-linux-gnu
   export BINDGEN_EXTRA_CLANG_ARGS="-I/usr/lib/gcc/x86_64-linux-gnu/13/include -I/usr/include -I/usr/include/x86_64-linux-gnu"
   ```
3. **flag ต่างจาก op-geth** — op-reth ใช้ `--chain <genesis.json>`, `--rollup.sequencer`, `--rollup.disable-tx-pool-gossip`
4. **security** — ทุก endpoint bind `127.0.0.1` เท่านั้น (กฎฟลีต ห้าม 0.0.0.0/public)
