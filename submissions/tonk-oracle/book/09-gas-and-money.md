# เงินกับแก๊ส — ETH, Paymaster, deposit

chain มีตัวอาศัยอยู่ได้ต้องมีค่าส่ง — block ทุก block ที่ผ่านมาใน WS-06 มันเดิน ment derive safe ได้ P2P ไหลได้ แต่ถ้าจะส่ง transaction จริง จ่ายค่า gas จริง ต้องเข้าใจก่อนว่าเงินบน chain นี้มันทำงานยังไง

คำตอบสั้นๆ คือ **native gas token ของ OP-Stack = ETH** เสมอ ตั้งแต่พฤษภาคม 2024 เป็นต้นมา ไม่ว่าจะสร้าง L2 ไหนก็ตาม ถ้ายังอยู่ใน Optimism ecosystem แล้วจะจ่าย gas ด้วยอะไรก็ต้องผ่าน ETH ทั้งนั้น

แต่ทำไม?

---

## 9.1 native gas = ETH — และทำไม Custom Gas Token ถึงตาย

ก่อน พ.ค. 2024 มี concept หนึ่งที่ฟังดูน่าสนใจมากสำหรับทีมที่อยาก launch L2 — เรียกว่า **Custom Gas Token (CGT)** คือแทนที่จะใช้ ETH จ่าย gas ก็สร้าง token ขึ้นมาเองแล้วกำหนดให้มันเป็น native token ของ chain แทน ฟังดูเหมาะกับ project ที่อยากให้ ecosystem token มีความสำคัญ ให้ holder ของ token ตัวเองจ่าย fee ได้โดยตรง

แต่พอ Optimism team ลองใช้งานจริงก็เจอ **3 ปัญหาหนักมาก** ที่แก้ได้ยาก:

### ปัญหาที่ 1: Fee calculation เพี้ยน

OP-Stack คำนวณ L1 data fee โดยอ้างอิง ETH price บน Ethereum mainnet — เพราะ batch data ที่ batcher ส่งขึ้น L1 ต้องจ่ายด้วย ETH จริงๆ พอ native token ของ L2 ไม่ใช่ ETH แต่ fee overhead ยังคิดเป็น ETH อยู่ มันต้องมี price feed มาแปลงอัตราตลอดเวลา และ price feed นั้นก็ต้องเชื่อถือได้ ไม่ล้าหลัง ไม่ถูก manipulate

พอ token เล็กที่ไม่ได้ trade บน exchange ใหญ่มาใช้ CGT ก็ไม่มี price feed ที่ดีพอ — fee ที่เก็บกับ fee ที่จ่ายจริงบน L1 มันต่างกัน chain อาจขาดทุนงัม หรือเก็บแพงเกินไปจนไม่มีคนใช้

### ปัญหาที่ 2: แก้ OptimismPortal ไม่ผ่าน audit

OptimismPortal คือสัญญาหลักที่อยู่บน L1 รับฝาก ETH เข้า L2 ส่ง message ข้าม chain — สัญญานี้ผ่าน audit มาเป็น version ที่เสถียรแล้ว ตรง safe ตาม Superchain standard

พอจะรองรับ CGT ต้องแก้ Portal ให้รับ token ERC-20 ได้ด้วย ไม่ใช่แค่ ETH — แต่ทุกครั้งที่แก้ portal ต้องผ่าน audit ใหม่ และการเพิ่ม logic รับ token หลายชนิดมันเพิ่ม attack surface ขึ้นอย่างมาก Optimism ลองออกแบบ แต่ audit ผ่านยาก ความเสี่ยงสูงกว่าประโยชน์ที่ได้

### ปัญหาที่ 3: ไม่รองรับ upgrade path ใหม่

OP-Stack กำลัง evolve เร็วมาก — Holocene, Jovian, Isthmus มาติดๆ กัน feature ใหม่แต่ละ fork ต้องการให้ Portal กับ SystemConfig โครงสร้างแน่นอน CGT ต้องการ logic พิเศษใน Portal → ทุก upgrade จะต้องแบก code CGT ไปด้วยตลอด ทำให้ upgrade ช้า ซับซ้อน และเสี่ยงขึ้นเรื่อยๆ

**สรุป:** CGT deprecated พ.ค. 2024 ไม่ใช่เพราะ bad idea แต่เพราะ implementation cost ในชั้น L1 contract มันสูงกว่าที่คิด และ trade-off ไม่คุ้ม

chain 20260619 ของ WS-06 ก็ใช้ ETH เป็น native gas เลย — ไม่มี custom token ไม่ต้องตั้ง price feed

---

แต่ถ้า ETH เป็น gas แล้ว user ที่มีแต่ token อื่นล่ะ — จะทำยังไง?

---

## 9.2 Paymaster ERC-4337 — ตัวแทนทางการของ CGT

Optimism ไม่ได้บอกว่า "ทนๆ ซื้อ ETH เองเถอะ" พวกเขา redirect solution ไปที่ **account abstraction** แทน — โดยเฉพาะ **Paymaster ตาม ERC-4337**

Paymaster คือสัญญาที่ทำหน้าที่ **จ่าย gas แทน user** ใน flow ของ ERC-4337 (UserOperation) แทนที่ EOA จะต้องมี ETH ในกระเป๋าตัวเองเพื่อ submit tx Paymaster สามารถ intercept ตรงนั้นแล้วบอก EntryPoint ว่า "gas batch นี้ฉันจ่ายให้"

ใช้งานเมื่อไหร่? มี 4 กรณีหลักที่ Paymaster มีประโยชน์จริงๆ:

**กรณีที่ 1: User ไม่มี ETH เลย**
user ใหม่ที่เพิ่ง onboard เข้า L2 ยังไม่ได้ deposit ETH — ถ้าให้เขา send tx เองก็ทำไม่ได้ Paymaster ช่วย sponsor gas ให้ก่อน แลกกับ proof ว่าเขามี token อื่น หรือ project ตัดสินใจ subsidize

**กรณีที่ 2: จ่าย gas เป็น token อื่น**
user อาจมี USDC หรือ project token ของ app เอง — Paymaster รับ token จาก user แปลง ETH จ่ายต่อ ฝั่ง user ไม่ต้องรู้ว่า gas คือ ETH เลย นี่คือ UX ที่ CGT พยายามทำ แต่ทำในชั้น application แทนชั้น L1 protocol

**กรณีที่ 3: Sponsor / Gasless transaction**
dApp หรือ game อาจอยากให้ user เล่นฟรีไปก่อน — Paymaster เป็น mechanism จ่าย gas แทนทั้งหมด ฝั่ง dev เป็นคนแบกต้นทุน สร้าง user acquisition funnel โดยไม่ให้ user ต้องซื้อ ETH

**กรณีที่ 4: Onboarding**
chain ใหม่ที่เพิ่ง launch ยังไม่มี ETH หมุนเวียน — Paymaster ช่วยให้ initial user เริ่มต้น tx ได้โดยไม่ติด chicken-and-egg problem (ต้องมี ETH ถึงจะ tx ได้ แต่ก็ต้องมี tx ก่อนถึงจะได้ ETH)

ใน WS-06 Tonk เขียน paymaster integration ใน PR #12 — ลง EntryPoint บน chain 20260619 ทดสอบ UserOperation แบบ sponsored ให้ fleet account ส่ง tx ได้โดยไม่ต้องมี ETH ในกระเป๋า นั่นคือตอนที่เห็นครั้งแรกว่า ERC-4337 ไม่ใช่แค่ spec บนกระดาษ มันใช้งานได้จริงบน L2 ที่ build เอง

---

แต่ก่อน Paymaster จะทำงานได้ มีก้าวเล็กๆ ที่ต้องทำก่อน — ETH ต้องอยู่บน L2 ก่อน ถ้า L2 ว่างเปล่า Paymaster ก็ไม่มีอะไรจ่าย

---

## 9.3 deposit ETH เข้า L2 — OptimismPortal.depositTransaction

ETH บน L2 ไม่ได้เกิดขึ้นเอง มันต้อง **bridge มาจาก L1** ผ่านกลไก deposit

กลไกนี้ทำงานผ่าน contract ที่อยู่บน L1 ชื่อว่า **OptimismPortal** — ใน chain 20260619 อยู่ที่ address:

```
0x08d045e317f924a9428959ac557f198f95a7b519
```

function ที่ใช้คือ `depositTransaction` — signature เต็มๆ คือ:

```solidity
function depositTransaction(
    address _to,
    uint256 _value,
    uint64 _gasLimit,
    bool _isCreation,
    bytes memory _data
) external payable;
```

ทำงานยังไง? พอ call `depositTransaction` พร้อมส่ง ETH ไปด้วย (เป็น `msg.value`) Portal จะ emit event `TransactionDeposited` ไว้บน L1 — แล้ว op-node ที่กำลัง derive อยู่จะดึง event นั้นออกมาแล้ว include เป็น special "deposit tx" ใน L2 block ถัดไปที่ derive จาก L1 origin นั้น

ผลลัพธ์คือ ETH ที่ส่งเข้า Portal บน L1 จะ "ปรากฏ" ใน address `_to` บน L2

### ตัวอย่าง: deposit ETH ด้วย cast

สมมติอยากโอน `0.01 ETH` เข้า L2 ไปที่ address เดิม (ตัวเอง) `cast send` ทำได้ตรงๆ:

```bash
# ตัวแปร
L1_RPC="https://sepolia.infura.io/v3/<KEY>"          # L1 RPC
PORTAL="0x08d045e317f924a9428959ac557f198f95a7b519"  # OptimismPortal บน L1
MY_ADDR="0xYOUR_ADDRESS"                              # address ของเรา
PRIVATE_KEY="0xYOUR_PRIVATE_KEY"                      # L1 private key

cast send \
  --rpc-url "$L1_RPC" \
  --private-key "$PRIVATE_KEY" \
  --value 0.01ether \
  "$PORTAL" \
  "depositTransaction(address,uint256,uint64,bool,bytes)" \
  "$MY_ADDR" \
  10000000000000000 \
  100000 \
  false \
  "0x"
```

อธิบาย argument แต่ละตัว:

| argument | ค่า | ความหมาย |
|---|---|---|
| `_to` | `$MY_ADDR` | address ปลายทางบน L2 |
| `_value` | `10000000000000000` | 0.01 ETH ในหน่วย wei |
| `_gasLimit` | `100000` | gas limit สำหรับ tx บน L2 |
| `_isCreation` | `false` | ไม่ใช่ contract deployment |
| `_data` | `0x` | ไม่มี calldata เพิ่ม (แค่โอน ETH) |

`--value 0.01ether` ด้านบนคือ ETH ที่จะถูก deposit จริงๆ — ต้องตรงกับ `_value` ไม่งั้น Portal revert

### ⚠️ Caveat สำคัญ: balance = 0 ทันที ≠ บั๊ก

นี่คือจุดที่ทำให้คนงงได้มาก — พอ tx deposit ผ่านบน L1 แล้ว ลอง check balance บน L2 ทันที:

```bash
cast balance $MY_ADDR --rpc-url http://127.0.0.1:18780
# 0
```

เห็น 0 แล้วตกใจว่า bridge พัง — **แต่ไม่ใช่**

กลไก derive ต้องรอ op-node รับ L1 block ที่มี deposit event แล้ว derive ออกมาเป็น L2 block ก่อน process นั้นใช้เวลา **~3-5 นาที** โดยเฉพาะช่วง L1 block time + confirmation time

ดูได้ว่า deposit tx ถูก included หรือยังโดย check L1 receipt:

```bash
# ดู receipt บน L1 ก่อน
cast receipt $TX_HASH --rpc-url "$L1_RPC"
# ถ้า status=1 แปลว่า Portal รับแล้ว — รอ derive
```

แล้วรอแล้วเช็คซ้ำ:

```bash
# รอสัก 5 นาทีแล้วเช็ค L2 balance อีกที
cast balance $MY_ADDR --rpc-url http://127.0.0.1:18780
# 10000000000000000 (0.01 ETH)
```

ใน WS-06 ช่วง deposit นี้ fleet หลายคนช่วยกัน fund account ให้มี ETH พอทดสอบ — Tonk เป็นคนทำ deposit ครั้งแรก แล้วรอจนเห็น balance ขึ้นจริงบน L2 ก่อนถึงบอกว่าใช้งานได้

### รอ derive อย่างมีสติ: ดู syncStatus

ถ้าอยากเห็นว่า op-node derive มาถึงไหนแล้ว เทียบกับ L1 block ที่ deposit อยู่:

```bash
cast rpc optimism_syncStatus --rpc-url http://127.0.0.1:18791 | jq '{
  safe_l2: .safe_l2.number,
  unsafe_l2: .unsafe_l2.number,
  current_l1: .current_l1.number
}'
```

ถ้า `current_l1` ยังไม่ถึง block ที่ deposit tx อยู่ แปลว่ายังรออยู่ปกติ พอ `current_l1` ผ่าน block นั้นแล้ว balance บน L2 ควรขึ้น

---

### ทำไม balance = 0 ทันทีถึง "normal"

เข้าใจได้จาก architecture — deposit ไม่ใช่ instant relay อย่าง bridge ที่ตีเป็น IOU แล้วให้ wrapped token ทันที deposit ใน OP-Stack คือ **L1 → L2 message derivation** ซึ่งต้องผ่าน consensus ของ op-node ก่อน ถ้า shortcut ตรงนี้ได้มันก็จะ shortcut trustless proof ได้ด้วย — ซึ่งก็ผิด หลักการ

นั่นคือทำไม 3-5 นาทีมันเป็น feature ไม่ใช่ bug

---

## เงิน → Paymaster → การทดสอบ

พอมี ETH บน L2 แล้ว flow ของ Paymaster ทดสอบได้แบบนี้:

```bash
# 1. deploy EntryPoint (ERC-4337) ถ้ายังไม่มี
# 2. deploy Paymaster contract
# 3. deposit ETH เข้า Paymaster (เพื่อให้มีงบจ่าย gas แทน user)
cast send \
  --rpc-url http://127.0.0.1:18780 \
  --private-key "$L2_PRIVATE_KEY" \
  --value 0.005ether \
  "$PAYMASTER_ADDR" \
  "deposit()"

# 4. สร้าง UserOperation จาก user account (ไม่ต้องมี ETH)
# 5. ส่งผ่าน bundler → EntryPoint validate → Paymaster จ่าย gas
```

PR #12 ของ Tonk ทำ step ที่ 1-4 ไว้ครบ — รวมทั้ง test script ที่ generate UserOperation แล้ว check ว่า tx ผ่านโดย user wallet balance = 0 ตลอด

ผลที่ได้คือ proof จริงว่า CGT ไม่จำเป็นต้องอยู่ที่ชั้น protocol ถ้า Paymaster layer ทำงานได้ user ก็ไม่รู้สึกว่าต้องมี ETH ก่อน

---

## ทำไม CGT ตายแล้ว Paymaster ถึงเป็นทางที่ดีกว่า

เปรียบง่ายๆ: CGT คือการสร้างถนนใหม่ทั้งสาย เพื่อให้รถขับได้โดยไม่ต้องเติมน้ำมัน — ฟังดูดี แต่ต้องรื้อระบบทั้งหมด

Paymaster คือการสร้าง **station เติมเชื้อเพลิงฟรี** ไว้ระหว่างทาง รถยังเป็นรถเดิม ถนนยังเป็นถนนเดิม แต่ user ไม่ต้องจ่ายน้ำมันเอง — project จ่ายให้ที่ station

trade-off ชัดเจน:

| | CGT | Paymaster |
|---|---|---|
| layer ที่แก้ | L1 Protocol | Application |
| audit risk | สูง (แก้ Portal) | ต่ำ (แก้เฉพาะ app contract) |
| upgrade compat | ซับซ้อน | ง่าย (independent) |
| price feed | ต้องการ | optional |
| UX สำหรับ user | native | เหมือน native (ถ้า bundler ดี) |

Paymaster แพ้แค่เรื่องเดียวคือ latency — ต้องผ่าน bundler ก่อน EntryPoint ซึ่งเพิ่ม hop แต่ในทางปฏิบัติสำหรับ L2 ที่มี block time 2-3 วินาที ความแตกต่างนั้นเล็กมาก

---

## ภาพรวมทั้งหมด

ถ้าลาก timeline ตั้งแต่ ETH ยังไม่อยู่บน L2 จนถึง user ส่ง tx ได้โดยไม่มี ETH ในกระเป๋า มันมีอยู่ 3 ขั้น:

```
L1 (Sepolia)                   L2 (chain 20260619)
     │                                │
     │  depositTransaction()          │
     │ ──────────────────────────────▶│
     │  OptimismPortal emit event     │
     │                   op-node derive (~3-5 min)
     │                                │ ETH ปรากฏ
     │                                │
     │                     Paymaster.deposit()
     │                                │ paymaster มีงบ
     │                                │
     │                     user submit UserOperation
     │                     bundler → EntryPoint → Paymaster จ่าย gas
     │                                │ tx ผ่าน, user wallet ยัง 0
```

ขั้นที่ 1 (deposit) ทำครั้งเดียวตอน setup ขั้นที่ 2 (paymaster fund) ทำตอน deploy ขั้นที่ 3 (user tx) ไม่ต้องรู้เรื่อง ETH เลย

---

fleet ช่วยกัน fund account กันในช่วง WS-06 — ตอนแรกมี ETH ไม่พอ ทดสอบ Paymaster ไม่ได้ Tonk deposit เพิ่มแล้วแจ้ง fleet ให้มาใช้ account กลางที่ Paymaster sponsor ค่า gas ให้ได้เลย

นั่นแหละคือจุดที่เห็นชัดว่า "chain มีชีวิต" ไม่ใช่แค่ sync ได้ แต่ส่ง tx ได้ มีเงินหมุน มีคนใช้

---

chain มีเงินแล้ว มี gas แล้ว มีคนส่ง tx ได้แล้ว — แต่มีสิ่งหนึ่งที่ยังไม่พูดถึงตลอดทั้งเล่มคือ ทุก port ที่เปิดอยู่นั้นเปิดให้ใครมาอยู่บ้าง และถ้าตั้ง RPC ผิด debug API หลุดสู่ public อะไรจะเกิดขึ้น — บทถัดไปจะตอบตรงนั้น
