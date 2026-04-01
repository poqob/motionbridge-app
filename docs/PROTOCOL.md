# Motion Bridge - İletişim Protokolü ve Handshake Dokümantasyonu

Bu doküman, Masaüstü (Host) uygulamasını geliştirecek yazılımcı için hazırlanmıştır. Mobil uygulamanın ağ üzerinden masaüstü ile nasıl iletişim kurduğunu, keşif (discovery) algoritmalarını ve veri modellerini (payloads) detaylandırır.

## 1. Mimari Genel Bakış
Motion Bridge, performans ve güvenilirliği optimize etmek için **hibrit bir iletişim modeli (UDP + WebSocket)** kullanır:
1. **Keşif ve Eşleşme (Handshake):** UDP Broadcast üzerinden cihazların birbirini bulması ve onaylaşması. Eşleşme sayesinde sadece yetkili (eşleşen) cihazlar birbirleriyle veri alışverişi yapabilir.
2. **Kritik Olayların Aktarımı (WebSocket):** Tıklama (click) ve sürükleme (drag) başlangıç/bitiş gibi kesin iletilmesi gereken ("lossless") durumlar WebSocket üzerinden gönderilir.
3. **Akıcı Veri Aktarımı (UDP):** Fare hareketi (move), kaydırma (scroll) ve sürükleme sırasındaki koordinat güncellemeleri gibi yüksek frekanslı kayıplı ("lossy") veriler UDP üzerinden gönderilmeye devam eder.

---

## 2. Keşif (Discovery) ve Handshake Mekanizması

### Aşama 1: Mobil Cihazın Yayını (Broadcast - UDP)
Mobil cihaz, uygulaması açık olduğu sürece (veya eşleşme sağlanana kadar) yerel ağa her **2 saniyede bir** UDP Broadcast paketi gönderir.
- **Hedef IP:** `255.255.255.255` (Network Subnet Broadcast)
- **Hedef Port:** `44444` (Masaüstü yazılımı bu portu UDP olarak dinlemelidir)

**Örnek Broadcast Payload (JSON):**
```json
{
  "type": "discovery",
  "id": "1940a233b2a",
  "name": "Controller_192",
  "role": "controller",
  "os": "android",
  "ip": "192.168.1.192",
  "port": 5000,
  "version": 1
}
```

### Aşama 2: Masaüstü (Host) Yazılımının Yanıtı (Handshake Çift Yönlü Güvenlik)
Masaüstü yazılımı `44444` portundan bu paketi aldığında, kullanıcı eşleşmeye onay verdiyse (veya otomatik bağlantı açıksa), mobil cihazın `ip` ve `port` (Örn: 5000) adresine doğrudan (Unicast UDP) bir onay (ACK) mesajı gönderir.

**Örnek Masaüstü Yanıtı (UDP):**
```json
{
  "type": "discovery_ack",
  "host_name": "Desktop-PC",
  "data_port": 44444,
  "ws_port": 44445
}
```
**Alanlar:**
* `data_port`: Mobil uygulamanın yüksek frekanslı UDP (Move vs) verilerini göndereceği port.
* `ws_port`: Masaüstünün WebSocket sunucusunu çalıştırdığı ve mobilin bağlanacağı port.

### Aşama 3: WebSocket Bağlantısının Kurulması
Mobil cihaz `discovery_ack` yanıtını aldıktan sonra, belirtilen `ws_port` üzerinden masaüstüne WebSocket bağlantısı açar (Örn: `ws://[HOST_IP]:44445`). WebSocket bağlantısı başarıyla kurulduğunda **Handshake tamamlanmış olur** ve olay aktarımı başlar.

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
4. **WebSocket dinleyicisinde:** Gelen `C`, `DRAG_START` ve `DRAG_END` komutlarını yakalayarak İşletim Sistemi API'leri üzerinden tıklama bas/bırak (mouse down/up) komutlarına dönüştür.
5. **UDP dinleyicisinde:** Gelen `M`, `S`, `D` paketlerini yakalayarak anlık imleç hareketini ve tekerlek kaydırmasını gerçekleştir. (Sadece WebSocket üzerinden bağlı / handshake yapılmış cihazların IP'sinden gelen UDP paketlerini işle).
