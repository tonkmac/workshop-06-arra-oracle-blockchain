# บั๊กธงเดียวที่ฆ่าทั้งโหนด — op-node --verbosity

---

พอ build op-geth กับ op-node เสร็จก็รู้สึกว่าอยู่บนเส้นทางถูกแล้ว ไบนารีอยู่ในมือ Go toolchain พร้อม binary version ตรง บทที่แล้วแก้ปัญหา no-root ไปแล้ว เหลือแค่ "เปิดโหนดแล้วซิงค์" ก็จบ

แต่บางครั้ง บั๊กที่เล็กที่สุด ก็ฆ่าได้เร็วที่สุดด้วย

---

## 4.1 วันที่ workshop sync.sh ทำให้โหนดล่มใน 2 วินาที

workshop kit ที่ Nova ปล่อยออกมาที่ `:8181` มี `sync.sh` อยู่ไฟล์หนึ่ง หน้าที่มันก็คือโหลด genesis, rollup config, jwt แล้วเปิด op-geth กับ op-node พร้อมกัน ใครก็ตามที่เพิ่งลงมือสร้าง follower ก็จะรัน script นี้ก่อนเป็นอันดับแรก มันเป็น starting point ที่ workshop ออกแบบมาให้ทุกคนใช้

Tonk รัน `sync.sh` ตามนั้น

op-geth ขึ้นปกติ

แล้ว op-node ก็ตาย

```
t=2026-06-20T11:02:37 lvl=crit msg="Application failed"
  message="flag provided but not defined: -verbosity"
```

`lvl=crit` ไม่ใช่ warning ไม่ใช่ error ธรรมดา — มัน crash ออกไปเลย process ไม่อยู่แล้ว

ใช้เวลาไม่ถึง 2 วินาทีตั้งแต่เปิดจนตาย

---

## 4.2 ต้นตอ: flag เดียวกัน ความหมายต่างกัน สองโปรแกรมต่างกัน

ปัญหาอยู่ที่ `sync.sh` บรรทัดนี้

```bash
# ใน sync.sh ของ workshop (version ก่อนแก้)
./op-geth \
  --verbosity=3 \
  ... (flags อื่น)

./op-node \
  --verbosity=3 \     # ← ตรงนี้คือปัญหา
  ...
```

script ส่ง `--verbosity=3` ให้ **ทั้งคู่** — ราวกับว่ามันต้องรับ flag เดียวกัน

แต่ความจริงคือ:

**op-geth** — สืบทอดมาจาก go-ethereum รุ่นเก่า ซึ่ง geth ใช้ `--verbosity` มาตั้งแต่ต้น ค่าเป็น integer 0–6 แทน log level รับ `--verbosity=3` ได้ปกติ

**op-node v1.19.0** — เขียนใหม่ใน repo `optimism` โดยทีม OP Labs ระบบ log ใช้ตัวเก่าของ Optimism ไม่ใช่ geth เลย flag ที่ op-node รับคือ `--log.level` ค่าเป็น string เช่น `info`, `debug`, `warn` — ไม่มี `--verbosity` เลยสักตัว

พอ Go flag parser เจอ flag ที่ไม่ได้ declare ไว้ มันไม่ warning ไม่ skip มัน **abort ทันที** พร้อม `"flag provided but not defined"` ซึ่งนั่นแหละคือ lvl=crit ที่เห็น

ความสัมพันธ์ระหว่างสองโปรแกรมคือ op-node เป็น consensus layer — คุมการ derive block จาก L1 ส่วน op-geth เป็น execution layer รับ payload มาประมวลผล ทั้งคู่ทำงานร่วมกันผ่าน Engine API แต่นั่น **ไม่ได้แปลว่า** flag command-line ต้องเหมือนกัน คนละ codebase คนละทีมเขียน คนละ flag system เลยด้วย

---

## 4.3 ทางแก้: เปลี่ยน flag ให้ตรงโปรแกรม

Tonk เปิด op-node source ดู — `op-node/cmd/main.go` และ flag definitions ใน `op-node/flags/` — พบว่า log level flag คือ

```
--log.level    string    log level (trace|debug|info|warn|error|crit)  (default: "info")
```

ไม่มี `--verbosity` ในรายการ flag ของ op-node เลย

ทางแก้จึงตรงไปตรงมา: `sync-fixed.sh` แก้บรรทัด op-node ให้ใช้ flag ที่ถูก

```bash
# sync-fixed.sh (version ที่แก้แล้ว)
"${OP_GETH_BIN}" \
  --verbosity=3 \                # op-geth รับได้ ใช้ต่อได้
  --datadir="${DATA_DIR}/geth" \
  ... (flags op-geth อื่น)

"${OP_NODE_BIN}" \
  --log.level=info \             # op-node ใช้อันนี้ ไม่ใช่ --verbosity
  --l1="${L1_RPC}" \
  --l2="${L2_AUTH}" \
  --rollup.config="${ROLLUP_JSON}" \
  --rpc.addr=127.0.0.1 \
  --rpc.port=18791 \
  ... (flags op-node อื่น)
```

พอแก้แล้วรันใหม่ — op-node ขึ้น process ค้างอยู่ เริ่ม print log ปกติ ไม่ crash

สองบรรทัดต่างกัน ผลต่างกันโดยสิ้นเชิง

---

## 4.4 บทเรียน: เครื่องมือพี่น้องกัน ≠ flag พี่น้องกัน

บั๊กนี้สอนอะไรบางอย่างที่ไม่ใช่แค่เรื่อง flag

ใน OP-Stack มีชื่อที่ขึ้นต้นด้วย `op-` หลายตัว op-geth, op-node, op-batcher, op-proposer พวกมันทำงานด้วยกัน คุยกันผ่าน JSON-RPC อยู่ใน ecosystem เดียวกัน ชื่อก็ดูเหมือนมาจากครอบครัวเดียว

แต่ภายในนั้น แต่ละตัวมีประวัติศาสตร์ของตัวเอง op-geth แตก fork มาจาก go-ethereum ซึ่งมีประวัติยาวนานกว่าสิบปี convention บางอย่างฝังลึกจนไม่เปลี่ยน `--verbosity` เป็นหนึ่งในนั้น op-node เขียนใหม่ตั้งแต่ต้นใน repo `optimism` ใช้ structured logging library ของ OP Labs เอง ไม่ต้องสืบทอด convention geth มา

ดังนั้น: **ชื่อโปรแกรมดูคล้ายกัน ≠ flag ตรงกัน**

มีแนวคิดหนึ่งที่ควรจำ — "ตรวจสอบ flag ที่โปรแกรมรับจริง อย่าสมมุติจาก pattern ของพี่น้อง" วิธีที่น่าเชื่อถือที่สุดคือดู source โดยตรง หรือรัน `--help` แล้วอ่าน:

```bash
# ดู flag ที่ op-node รับจริง
./op-node --help 2>&1 | grep -E "log|verbosity"
```

output จะไม่มี `verbosity` เลย มีแต่ `--log.level` กับ `--log.format`

```bash
# เทียบกับ op-geth
./geth --help 2>&1 | grep -E "verbosity|log.level"
```

จะเห็น `--verbosity` อยู่ใน geth แต่ไม่มี `--log.level`

ถ้า verify ตรงนี้ก่อน ก็จะไม่ต้องเห็น `lvl=crit` ในชีวิต

---

## 4.5 ทำไมมันถึงเป็น "crit" ไม่ใช่แค่ warning

มีคนอาจสงสัยว่า ทำไม Go runtime ถึง panic level ขนาดนี้เพียงเพราะ flag ที่ไม่รู้จัก

คำตอบอยู่ใน design philosophy ของ Go standard library `flag` package พฤติกรรม default คือ **error and exit** เมื่อเจอ flag ที่ไม่ได้ define ไว้ ไม่มี silent ignore ไม่มี "continue with defaults" มัน fail fast เพราะ Go ถือว่า flag ที่ไม่รู้จัก = ผู้ใช้ตั้งค่าผิด และถ้า continue ไปต่อโดยไม่สนใจ = โปรแกรมทำงานต่างจากที่ผู้ใช้คาดหวัง ซึ่งอันตรายกว่า crash

สำหรับระบบ blockchain node ที่ต้องการ correctness สูง การ fail fast แบบนี้ถูกต้อง — ดีกว่าให้โหนดรันไปโดยไม่รู้ว่า log level ที่ตั้งไปไม่ได้ถูก apply จริง

OP Labs เลือก design นี้โดยตั้งใจ

---

## 4.6 ตรวจสอบก่อนรัน: เช็ค flag ให้เป็นนิสัย

จากบั๊กนี้เกิดแนวทางปฏิบัติหนึ่งที่ Tonk เพิ่มเข้าไปใน `sync-fixed.sh` — dry-run flag check ก่อน start จริง

แนวคิดคือ ถ้าจะรัน op-node ด้วย flag ชุดหนึ่ง ให้ลองรัน `--help` ก่อนแล้ว grep หา flag ที่จะใช้ ถ้าไม่เจอ = flag ผิด อย่าเพิ่ง start process จริง

```bash
# ตัวอย่าง pre-flight check ใน script
check_flag() {
  local bin="$1"
  local flag="$2"
  if ! "$bin" --help 2>&1 | grep -q -- "$flag"; then
    echo "ERROR: $bin does not accept $flag — aborting"
    exit 1
  fi
}

check_flag "${OP_NODE_BIN}" "log.level"   # ควรเจอ
# check_flag "${OP_NODE_BIN}" "verbosity" # จะ abort ถูกต้อง
```

ไม่ต้องซับซ้อน แค่ "ถามก่อนบอก" แทนที่จะ "บอกแล้วค่อยรู้ว่าผิด"

---

## 4.7 เปรียบเทียบ flag ระหว่างสองโปรแกรมให้ชัด

เพื่อไม่ให้สับสนในอนาคต นี่คือตารางเปรียบเทียบ flag logging ระหว่างสองโปรแกรม:

```
┌──────────────────────────────────────────────────────────┐
│           Log Level Flag — op-geth vs op-node            │
├─────────────────────┬────────────────────────────────────┤
│ โปรแกรม            │ flag ที่ใช้                        │
├─────────────────────┼────────────────────────────────────┤
│ op-geth v1.101702.2 │ --verbosity=<0-6>  (integer)       │
│                     │   0=silent, 3=info, 5=debug        │
├─────────────────────┼────────────────────────────────────┤
│ op-node v1.19.0     │ --log.level=<string>               │
│                     │   trace|debug|info|warn|error|crit │
└─────────────────────┴────────────────────────────────────┘
```

ไม่มีตัวไหนรับ flag ของอีกตัว ถ้าสลับกัน = crash

---

## 4.8 เครดิตและสิ่งที่เกิดจริง

บั๊กนี้ Tonk เจอและแก้เอง ไม่มีคนบอก — รัน workshop script ที่ workshop จัดให้ เจอ crash log อ่าน error message เปิด source ตาม เข้าใจ แก้ใน `sync-fixed.sh`

สิ่งที่น่าสังเกตคือ error message มันบอกชัดเจนมาก `"flag provided but not defined: -verbosity"` ถ้าอ่าน log แล้วเชื่อสิ่งที่มันบอก แก้ก็ไม่ยาก ปัญหาใหญ่คือถ้า **ไม่ดู log** หรือ **ดูแล้วไม่เชื่อ** แล้วไปค้นหา bug ที่ซับซ้อนกว่านั้น จะเสียเวลาไปโดยไม่จำเป็น

`lvl=crit` บอกอยู่แล้วว่ามันไม่ใช่เรื่องเล็ก

---

## 4.9 สรุปสิ่งที่ต้องรู้

```bash
# ผิด — op-node v1.19.0 ไม่รับ --verbosity
./op-node --verbosity=3 ...
# → lvl=crit msg="Application failed" message="flag provided but not defined: -verbosity"

# ถูก — ใช้ --log.level
./op-node --log.level=info ...
# → โหนดขึ้น process ค้าง ไม่ crash
```

กฎง่ายๆ: op-geth ใช้ `--verbosity` (integer), op-node ใช้ `--log.level` (string) เวลาเขียน script ที่เปิดทั้งคู่ flag ต้องแยกกันตามโปรแกรม

---

พอแก้ flag เสร็จก็ดูเหมือนว่าโหนดจะวิ่งได้แล้ว op-geth ขึ้น op-node ขึ้น ไม่มี crash ในช่วงแรกๆ

แต่นั่นเป็นแค่จุดเริ่มต้น

เพราะ op-node ที่รันอยู่นั้นกำลังพยายาม derive block จาก genesis ที่ดาวน์โหลดมาจาก `:8181` และ genesis ที่ว่า — มันตรงกับ chain จริงของ Nova หรือเปล่า ยังไม่รู้

คำตอบอยู่ในบทที่ 5
