# Motion Bridge - İletişim Protokolü ve Handshake Dokümantasyonu

Bu doküman, Masaüstü (Host) uygulamasını geliştirecek yazılımcı için hazırlanmıştır. Mobil uygulamanın ağ üzerinden masaüstü ile nasıl iletişim kurduğunu, keşif (discovery) algoritmalarını ve veri modellerini (payloads) detaylandırır.

## 1. Mimari Genel Bakış
Motion Bridge, performans ve güvenilirliği optimize etmek için **hibrit bir iletişim modeli (UDP + WebSocket)** kullanır:
1. **Keşif ve Eşleşme (Handshake):** UDP Broadcast üzerinden cihazların birbirini bulması ve onaylaşması. Eşleşme sayesinde sadece yetkili (eşleşen) cihazlar birbirleriyle veri alışverişi yapabilir.
2. **Kritik Olayların Aktarımı (WebSocket):** Tıklama (click) ve sürükleme (drag) başlangıç/bitiş gibi kesin iletilmesi gereken ("lossless") durumlar WebSocket üzerinden gönderilir.
3. **Akıcı Veri Aktarımı (UDP):** Fare hareketi (move), kaydırma (scroll) ve sürükleme sırasındaki koordinat güncellemeleri gibi yüksek frekanslı kayıplı ("lossy") veriler UDP üzerinden gönderilmeye devam eder.

---

## 2. Keşif (Discovery) ve Handshake Mekanizması

### Aşama 1: Masaüstü Yazılımının Yayını (Host Broadcast - UDP)
Masaüstü (Host) yazılımı, çalıştığı sürece ağdaki mobil cihazlara varlığını duyurmak için her **2 saniyede bir** UDP Broadcast paketi gönderir.
- **Hedef IP:** `255.255.255.255` (Network Subnet Broadcast)
- **Hedef Port:** `44446` (Mobil uygulama bu portu UDP üzerinden pasif olarak dinler)

**Örnek Host Broadcast Payload (JSON):**
```json
{
  "type": "host_announcement",
  "host_name": "Desktop-PC",
  "data_port": 44444,
  "ws_port": 44445
}
```

### Aşama 2: Mobil Cihazın Eşleşme Talebi (Pairing Request - UDP)
Mobil uygulama, dinlediği yayınlardan bir masaüstü seçtiğinde (veya daha önce eşleşilen bir cihaza otomatik bağlanmak istediğinde), masaüstünün `data_port` (Örn: 44444) adresine doğrudan (Unicast UDP) bir eşleşme talebi gönderir.

**Örnek Eşleşme Talebi (UDP):**
```json
{
  "type": "pairing_request",
  "id": "1940a233b2a",
  "name": "Controller_192",
  "os": "android",
  "port": 5000,
  "version": 1
}
```

### Aşama 3: Masaüstünün Onayı ve WebSocket Bağlantısı
Masaüstü yazılımı, eşleşme talebini aldığında (ve onaylandığında), mobil cihazın belirttiği `port` (Örn: 5000) adresine doğrudan (Unicast UDP) bir `discovery_ack` gönderir.

**Örnek Masaüstü Yanıtı (UDP):**
```json
{
  "type": "discovery_ack"
}
```

Mobil cihaz bu onayı aldıktan sonra, masaüstünün `ws_port` (Örn: `44445`) üzerinden WebSocket bağlantısı açar (Örn: `ws://[HOST_IP]:44445`). WebSocket bağlantısı başarıyla kurulduğunda **Handshake tamamlanmış olur** ve olay aktarımı başlar.

---

## 3. Veri Modelleri (Event Payloads)

Mobil cihaz, masaüstünü yönetirken eylemin kritiklik seviyesine göre UDP veya WebSocket kullanır. Tüm paketlerde `t` (type/tür) parametresi, paketin amacını belirler. 

### A. KRİTİK OLAYLAR (WEBSOCKET ÜZERİNDEN GÖNDERİLİR)
Bu olayların masaüstüne kesin ulaşması gerektiği için **WebSocket** üzerinden JSON formatında gönderilir.

#### Fare Tıklaması (Mouse Click)
Tek tıklama, sağ tıklama gibi eylemler tetiklendiğinde.
- `t`: "C" (Click)
- `b`: Tuş indeksi (`0`: Sol tık, `1`: Sağ tık)

**Örnek WebSocket Mesajı:**
```json
{ "t": "C", "b": 0 }
```

#### Sürükleme Başlangıcı ve Bitişi (Drag Start / End)
Bir nesneyi tutma ve bırakma anları kritik olduğundan WebSocket üzerinden iletilir. Sürükleme başlangıcında Host farenin sol tuşuna basılı tutmalı, bitişinde ise bırakmalıdır.
- Başlangıç `t`: "DRAG_START"
- Bitiş `t`: "DRAG_END"

**Örnek WebSocket Mesajları:**
```json
{ "t": "DRAG_START" }
```
```json
{ "t": "DRAG_END" }
```

#### 4 Parmak Dokunma (4-Finger Tap)
Trackpad üzerinde 4 parmakla aynı anda dokunulduğunda WebSocket üzerinden tek seferlik olarak iletilir. Genellikle yapıştırma (Paste / Ctrl+V) gibi işlemler için masaüstü yazılımında değerlendirilir.
- `t`: "TAP_4"

**Örnek WebSocket Mesajı:**
```json
{ "t": "TAP_4" }
```

#### 3 Parmak Kaydırma (3-Finger Swipe)
Trackpad üzerinde 3 parmakla eşik değeri aşacak kadar kaydırma yapıldığında WebSocket üzerinden tek seferlik olarak iletilir. Genellikle masaüstü değiştirmek veya görev görünümünü açmak için kullanılır (Mac'te Mission Control vb.).
- `t`: "SWIPE_3"
- `dir`: Parmakların fiziksel kaydırma yönünü verir (`"UP"`, `"DOWN"`, `"LEFT"`, `"RIGHT"`).
  - `"RIGHT"` : Parmaklar sağa kaydı. Eylem -> Masaüstünde soldaki ekrana (önceki sanal masaüstü) geçiş yapılmalıdır.
  - `"LEFT"`  : Parmaklar sola kaydı. Eylem -> Masaüstünde sağdaki ekrana (sonraki sanal masaüstü) geçiş yapılmalıdır.
  - `"UP"`    : Parmaklar yukarı kaydı. Eylem -> Masaüstü önizleme / Task View açılmalıdır.

**Örnek WebSocket Mesajı:**
```json
{ "t": "SWIPE_3", "dir": "RIGHT" }
```

#### Dikte (Speech-to-Text)
Kullanıcı mikrofona konuştuğunda ve cümle/nefes tamamlandığında (algılama sonlandığında) metin olarak gönderilir. Bu mesajlar da kaybolmaması adına WebSocket üzerinden gönderilir.
- `t`: "DICT"
- `text`: Algılanan tam ve düzeltilmiş yazı.
- `is_final`: Her zaman `true` olarak gelir (Masaüstü yazılımcısının klavye simülasyonunu eski kelimeleri silip tekrar yazmak gibi yöntemlerle zorlamamak için yalnızca final metinler yollanır).

**Örnek WebSocket Mesajı:**
```json
{
  "t": "DICT",
  "text": "Merhaba dünya nasılsın",
  "is_final": true
}
```

#### Ses Kontrolü (Volume / Mute)
Mobil uygulamadan ses seviyesi değiştirildiğinde veya sessize alındığında WebSocket üzerinden iletilir.
- `VOL` mesajı için `t`: "VOL", `v`: Ses seviyesi (0.0 ile 1.0 arası).
- `MUTE` mesajı için `t`: "MUTE", `v`: Sessiz durumu (`true` veya `false`).

**Örnek WebSocket Mesajları:**
```json
{ "t": "VOL", "v": 0.75 }
```
```json
{ "t": "MUTE", "v": true }
```

#### Medya Kontrolü (Media Control)
Kullanıcı medya oynatıcı kontrollerini kullandığında WebSocket üzerinden iletilir. Oynat, duraklat, sonraki şarkı veya önceki şarkı eylemlerini tetikler.
- `t`: "MEDIA"
- `action`: İstenilen işlem. Alabileceği değerler: `"PLAY"`, `"PAUSE"`, `"NEXT"`, `"PREV"`

**Örnek WebSocket Mesajları:**
```json
{ "t": "MEDIA", "action": "PLAY" }
```
```json
{ "t": "MEDIA", "action": "NEXT" }
```

### B. AKICI OLAYLAR (UDP ÜZERİNDEN GÖNDERİLİR)
Hızlı hareketler (gecikmeyi önlemek için) ve paket kaybının tolere edilebileceği durumlar **UDP** üzerinden Host'un `data_port` (Örn: 44444) adresine gönderilir.

#### Fare Hareketi (Mouse Move)
Trackpad'te parmak gezdirildiğinde saniyede yüksek FPS hızında akar.
- `t`: "M" (Move)
- `x`: Yatay eksendeki delta (bağıl değişim). Pozitif sağa, negatif sola.
- `y`: Dikey eksendeki delta (bağıl değişim). Pozitif aşağı, negatif yukarı.

**Örnek UDP Mesajı:**
```json
{ "t": "M", "x": 12.5, "y": -4.2 }
```

#### Kaydırma (Scroll)
Trackpad üzerinde iki parmak kaydırıldığında, fare tekerleği (scroll) etkisi yapar.
- `t`: "S" (Scroll)
- `x`: Yatay scroll deltası.
- `y`: Dikey scroll deltası.

**Örnek UDP Mesajı:**
```json
{ "t": "S", "x": 0.0, "y": 15.3 }
```

#### Cihaz Sensörü/Dimmer (Opsiyonel)
- `t`: "D" (Dim)
- `v`: 0.0 (en karanlık) ile 1.0 (en aydınlık) arasında bir değer.

**Örnek UDP Mesajı:**
```json
{ "t": "D", "v": 0.45 }
```

## Önerilen Masaüstü Yazılım Akışı
1. `44444` portunu UDP için, `44445` portunu WebSocket Sunucusu için dinlemeye başla.
2. UDP'den Keşif (Broadcast) paketi geldiğinde, cihaza onay veriliyorsa UDP üzerinden `discovery_ack` yanıtını don.
3. Mobil cihaz WebSocket (`ws://[HOST_IP]:44445`) üzerinden bağlandığında eşleşmeyi kesinleştir. Gelen cihaz ID'sini kaydet ki başka paketlerle karışmasın.
4. **WebSocket dinleyicisinde:** Gelen `C`, `DRAG_START`, `DRAG_END`, `SWIPE_3`, ve `DICT` komutlarını yakalayarak İşletim Sistemi API'leri üzerinden tıklama bas/bırak, swipe kısayolları ve metin yazdırma (keystroke) komutlarına dönüştür.
5. **UDP dinleyicisinde:** Gelen `M`, `S`, `D` paketlerini yakalayarak anlık imleç hareketini ve tekerlek kaydırmasını gerçekleştir. (Sadece WebSocket üzerinden bağlı / handshake yapılmış cihazların IP'sinden gelen UDP paketlerini işle).
