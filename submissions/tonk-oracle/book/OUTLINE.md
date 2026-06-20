---
title: "เชนจากศูนย์"
subtitle: "คู่มือเทคนิคสร้าง OP-Stack L2 จากสนามจริง — ติดตั้ง ปัญหา ทางแก้ และข้อควรระวัง"
author: Tonk Oracle (AI · ไม่ใช่คน · Rule 6)
date: 2026-06-20
language: Thai (kien-thai 7 frames)
register: technical field-manual (ตรง จริง มี proof)
target_chapters: 10
target_words_per_chapter: 2500-3500
source: WS-06 Oracle School — first-hand session 2026-06-20
parts: 3
---

# เชนจากศูนย์ — โครงเล่ม

> หนังสือเทคนิคสำหรับคนที่จะสร้าง OP-Stack L2 chain ใหม่ เขียนจากสนามจริง
> ทุก bug ทุกทางแก้ มาจากการลงมือทำจริงใน WS-06 · ให้เครดิตคนที่แก้/แนะนำเป็นคนๆ
> หลักการตลอดเล่ม: เชื่อ ≠ พิสูจน์ · verify ก่อนเคลม · honest by construction

## ภาค 1 — ปูพื้น (ทำไม + อะไร)

### บทที่ 1: เชื่อ vs พิสูจน์ — ทำไมต้องรัน follower เอง
target_words: 2500
subtopics:
  - 1.1 มี sequencer แล้วทำไมต้อง follower (trustless proof)
  - 1.2 head-match proof คืออะไร (byte-for-byte จาก L1)
  - 1.3 ของต้องห้าม: datadir-copy = assertion ไม่ใช่ proof
proof: HEAD-MATCH-PROOF.md · ws06-booklet.md บทที่ 1
credit: แนวคิด trustless = หลัก workshop ของ P'Nat

### บทที่ 2: กายวิภาค OP-Stack — L1, L2, batcher, op-node
target_words: 3000
subtopics:
  - 2.1 ตัวละคร 4 ตัว: op-geth, op-node, op-batcher, op-proposer
  - 2.2 batcher อัด batch → L1 (ที่มาของคำว่า rollup)
  - 2.3 safe_l2 (derive จาก L1) vs unsafe_l2 (P2P gossip)
  - 2.4 deposit/withdraw ผ่าน OptimismPortal
proof: rollup.json (optimism_rollupConfig) · diagram จาก booklet

## ภาค 2 — ลงมือสร้าง (ติดตั้ง + บั๊ก + ทางแก้)

### บทที่ 3: เครื่องเปล่า — build op-geth + op-node จาก source (no-root)
target_words: 3000
subtopics:
  - 3.1 VPS ไม่มี Go/binary/docker — โหลด Go ลง home-dir
  - 3.2 build op-geth v1.101702.2 + op-node v1.19.0
  - 3.3 ทำไมต้อง pin รุ่นล่าสุด (Jovian + Isthmus forks)
proof: build.sh · BUILD.md
credit: Tonk (build), Sombo/bongbaeng (เส้นทาง docker เป็นทางเลือก)

### บทที่ 4: บั๊กธงเดียวที่ฆ่าทั้งโหนด — op-node --verbosity
target_words: 2500
subtopics:
  - 4.1 op-geth รับ --verbosity, op-node ไม่รับ → crash
  - 4.2 op-node ใช้ --log.level
  - 4.3 บทเรียน: เครื่องมือพี่น้องกันไม่ได้รับ flag เดียวกัน
proof: op-node.log crit line · sync-fixed.sh
credit: Tonk (เจอ+แก้)

### บทที่ 5: ความจริงสามเวอร์ชัน — genesis forensics + moving target
target_words: 3500
subtopics:
  - 5.1 clock-wedge: genesis timestamp hex-conversion bug (0x6a35cd34 vs 0x6a360a34)
  - 5.2 batcherAddr ≠ L1 SystemConfig → Holocene reject "unauthorized submitter"
  - 5.3 :8181 genesis/rollup stale 3-way mismatch (geth-init vs rollup vs live)
  - 5.4 moving target: redeploy 4 รอบ/ชม. → อย่าไล่
proof: 3-way hash verify · BUILD.md bug B
credit: Nova (แก้ genesis/batcher), ชายกลาง (ท้วงทฤษฎี clock ได้ถูก — alive-but-stalled), B3/DustBoy/Orz/bongbaeng/Jizo/Tonk (verify), ชายกลาง (ขอ pause ไม่ไล่ moving target)

### บทที่ 6: ทางทะลุ blocker — authoritative config จาก sequencer เอง
target_words: 2500
subtopics:
  - 6.1 ปัญหา: static file (:8181) ตาม live chain ไม่ทัน
  - 6.2 optimism_rollupConfig จาก op-node ของ Nova เอง = ground truth
  - 6.3 schema ตรง rollup.json เป๊ะ → ประกบ genesis → derive ผ่าน
proof: fire-proof.sh · optimism_rollupConfig RPC
credit: Tonk (ค้นพบทางทะลุ)

## ภาค 3 — พิสูจน์ + เศรษฐศาสตร์ + ความปลอดภัย

### บทที่ 7: proof ที่โกหกไม่ได้ — guard + head-match (L1)
target_words: 2500
subtopics:
  - 7.1 genesis-consistency guard: abort ถ้าไม่ตรง = honest by construction
  - 7.2 head-match L1-derivation 6/6 byte-for-byte (safe_l2)
  - 7.3 Patterns over Intentions ฝังในโค้ด
proof: HEAD-MATCH-PROOF.md · guard code
credit: Tonk (guard+proof), Weizen (head-match คนแรกของ fleet), Orz (dual proof)

### บทที่ 8: สองเส้นทาง — P2P gossip + sequencer key
target_words: 2500
subtopics:
  - 8.1 Path 1 (L1 derive=safe) vs Path 2 (P2P gossip=unsafe) ทำพร้อมกัน
  - 8.2 "no p2p signer" → ต้องเติม --p2p.sequencer.key
  - 8.3 dual-path proof: L1 6/6 + P2P 4/4
proof: syncStatus · poll-prove
credit: DustBoy/B3 (diagnose no-p2p-signer), Nova (เติม key), Tonk/Orz (dual proof)

### บทที่ 9: เงินกับแก๊ส — ETH, Paymaster, deposit
target_words: 3000
subtopics:
  - 9.1 native gas = ETH (custom gas token deprecated พ.ค. 2024 — เหตุผล)
  - 9.2 Paymaster ERC-4337 = ตัวแทนทางการของ CGT (ใช้เมื่อไหร่)
  - 9.3 deposit ETH เข้า L2 ผ่าน OptimismPortal.depositTransaction
proof: cast deposit tx · Optimism docs CGT deprecation · PR #12 paymaster
credit: Tonk (paymaster PR#12 + deposit), fleet (ช่วยกัน fund)

### บทที่ 10: ข้อควรระวัง — security + fleet rules + บทเรียน
target_words: 3000
subtopics:
  - 10.1 service ต้อง bind 127.0.0.1 — ห้าม 0.0.0.0/public RPC (debug,engine API)
  - 10.2 อย่า inherit 0.0.0.0 จาก script ภายนอกมาดื้อๆ
  - 10.3 document + แจ้งฟลีตก่อน infra experiment (shared user)
  - 10.4 บทเรียนใหญ่: อย่า passive · verify ก่อนพูด · อย่าไล่ moving target · honest ไม่ปั้น
proof: gm-bo escalation · ws06-opstack-follower-infra.md
credit: gm-bo Guardian (จับ exposure), Bigboy + gmtk (reinforce fleet rules), TK (สอน behavior)

## ปิดเล่ม
forward-looking: ไม่ recap — เครื่องมือเปลี่ยนได้ แต่หลัก (พิสูจน์ ไม่ใช่เชื่อ · honest · verify) ไม่เปลี่ยน
