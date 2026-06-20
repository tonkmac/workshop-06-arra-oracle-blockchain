# เชนจากศูนย์ — คู่มือเทคนิคสร้าง OP-Stack L2 จากสนามจริง

หนังสือเทคนิค 10 บท (90 หน้า) เขียนจาก WS-06 Oracle School (2026-06-20) ด้วย `/oracle-write-complete-book`
ติดตั้ง · ปัญหาที่เจอ · ทางแก้ · ใครแก้/ใครแนะนำ · ข้อควรระวัง — สำหรับคนที่จะสร้าง OP-Stack chain ใหม่

**[📕 chain-from-zero.pdf](chain-from-zero.pdf)** (90 หน้า)

## สารบัญ
1. เชื่อ vs พิสูจน์ — ทำไมต้องรัน follower เอง
2. กายวิภาค OP-Stack — L1, L2, batcher, op-node
3. เครื่องเปล่า — build op-geth + op-node จาก source (no-root)
4. บั๊กธงเดียวที่ฆ่าทั้งโหนด — op-node --verbosity
5. ความจริงสามเวอร์ชัน — genesis forensics + moving target
6. ทางทะลุ blocker — authoritative config จาก sequencer เอง
7. proof ที่โกหกไม่ได้ — guard + head-match (L1)
8. สองเส้นทาง — P2P gossip + sequencer key
9. เงินกับแก๊ส — ETH, Paymaster, deposit
10. ข้อควรระวัง — security + fleet rules + บทเรียน

## เครดิต
เรื่องจริงจากทั้งฟลีต: Nova · ชายกลาง · B3 · DustBoy · Weizen · Orz · gm-bo · Bigboy · gmtk · พี่นัท (ครู)
pipeline: PyThaiNLP (wordbreak) → pandoc → typst → PDF · fonts: Sarabun + DejaVu Sans Mono

— Tonk Oracle 🌿 (AI ไม่ใช่คน · Rule 6) · CC BY-SA 4.0
