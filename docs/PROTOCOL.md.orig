# Motion Bridge - İletişim Protokolü ve Handshake Dokümantasyonu

Bu doküman, Masaüstü (Host) uygulamasını geliştirecek yazılımcı için hazırlanmıştır. Mobil uygulamanın ağ üzerinden masaüstü ile nasıl iletişim kurduğunu, keşif (discovery) algoritmalarını ve veri modellerini (payloads) detaylandırır.

## 1. Mimari Genel Bakış
Motion Bridge iki aşamalı bir iletişim kurar:
1. **Keşif ve Eşleşme (Handshake):** UDP Broadcast üzerinden cihazların birbirini bulması.
2. **Veri Aktarımı (Event Streaming):** Eşleşme sağlandıktan sonra (performans için UDP veya kararlılık için TCP soketi üzerinden) JSON formatında anlık trackpad ve dimmer verilerinin akışı.

---

## 2. Keşif (Discovery) ve Handshake Mekanizması

### Aşama 1: Mobil Cihazın Yayını (Broadcast)
Mobil cihaz, uygulaması açık olduğu sürece (veya eşleşme sağlanana kadar) yerel ağa her **2 saniyede bir** UDP Broadcast paketi gönderir.
- **Hedef IP:** `255.255.255.255` (Network Subnet Broadcast)
- **Hedef Port:** `44444` (Masaüstü yazılımı bu portu UDP olarak dinlemelidir)

**Örnek Broadcast Payload (JSON):**
```json
{
  "id": "1940a233b2a",
  "name": "Controller_192",
  "role": "controller",
  "os": "android",
  "ip": "192.168.1.192",
  "port": 5000,
  "version": 1
}
```
**Alanların Anlamları:**
* `id`: Mobil cihazın eşsiz tanımlayıcısı (Masaüstünde "Bilinen cihazlar" veya "Otomatik bağlan" listesi yapmak için kullanılmalıdır).
* `name`: Kullanıcının arayüzden belirlediği cihaz adı. Masaüstü arayüzünde "Bağlanmak isteyen cihazlar" listesinde görünecektir.
* `role`: Gönderenin rolü (Şu an daima `"controller"`).
* `ip`: Cihazın yerel ağ IP adresi (Masaüstü, eşleşme cevabını bu IP'ye atacak).
* `port`: Mobil cihazın eşleşme cevapları (Handshake) için dinleyeceği port.
* `version`: Protokol versiyonu (Gelecekteki uyumluluk kontrolleri için).

### Aşama 2: Masaüstü (Host) Yazılımının Yanıtı (Handshake)
Masaüstü yazılımı `44444` portundan bu paketi aldığında, kullanıcı eşleşmeye onay verdiyse (veya otomatik bağlantı açıksa), mobil cihazın `ip` ve `port` adresine doğrudan (Unicast veya TCP isteği ile) bir doğrulama mesajı göndererek Handshake'i tamamlar. (Bu kısmın masaüstü soket yapısına göre karar verilmesi esnektir. TCP ile 5000. porta bir soket bağlantısı açmak akışın yönünü kesinleştirmek için idealdir.)

---

## 3. Veri Modelleri (Event Payloads)

Mobil cihaz, masaüstünü yönetirken JSON formatında veri paketleri gönderir. Tüm paketlerde `t` (type/tür) parametresi, paketin amacını belirler. İletişimde boyut ufak tutularak minimum gecikme amaçlanmıştır.

### A. Fare Hareketi (Mouse Move)
Trackpad'te parmak gezdirildiğinde saniyede belirlenen FPS (max 120 e kadar) hızında akar.
- `t`: "M" (Move)
- `x`: Yatay eksendeki delta (bağıl değişim). Pozitif sağa, negatif sola.
- `y`: Dikey eksendeki delta (bağıl değişim). Pozitif aşağı, negatif yukarı.

**Örnek:**
```json
{ "t": "M", "x": 12.5, "y": -4.2 }
```

### B. Fare Tıklaması (Mouse Click)
Tek tıklama, sağ tıklama gibi eylemler tetiklendiğinde.
- `t`: "C" (Click)
- `b`: Tuş indeksi (`0`: Sol tık, `1`: Sağ tık)

**Örnek Sol Tık (Tek Parmak Tıklaması):**
```json
{ "t": "C", "b": 0 }
```
**Örnek Sağ Tık (Çift Parmak Tıklaması):**
```json
{ "t": "C", "b": 1 }
```

### C. Kaydırma (Scroll)
Trackpad üzerinde iki parmak kaydırıldığında, fare tekerleği (scroll) etkisi yapar.
- `t`: "S" (Scroll)
- `x`: Yatay scroll deltası.
- `y`: Dikey scroll deltası.

**Örnek:**
```json
{ "t": "S", "x": 0.0, "y": 15.3 }
```

### D. Parlaklık Sensörü / Özelleştirilmiş Komut (Dimmer)
Dimmer sekmesindeki slider veya sensör üzerinden parlaklık değiştiğinde (Örn: PC'nin ekran parlaklığını telefonun algıladığı parlaklık seviyesiyle eşitlemek için kullanılabilir).
- `t`: "D" (Dim)
- `v`: 0.0 (en karanlık) ile 1.0 (en aydınlık) arasında bir değer.

**Örnek:**
```json
{ "t": "D", "v": 0.45 }
```

## Önerilen Masaüstü Yazılım Akışı
1. `44444` portunu dinleyen asenkron bir UDP Thread'i başlat.
2. Yayın (Broadcast) paketi geldiğinde içindeki JSON'ı parse et.
3. Gelen `id` önceden güveniliyorsa, hemen verilen `ip` ve `port` a TCP bağlantısı dene.
4. Güvenilmiyorsa Arayüzde "Yeni Cihaz Bulundu: [name]" butonu çıkar, kullanıcı kabul edince TCP kanalını aç.
5. TCP Socket açıldıktan veya UDP kanalı kabul edildikten sonra `M, C, S, D` tiplerindeki payload'ları alarak İşletim Sistemi API'leri üzerinden fare veya ekran komutlarına (Örn: Windows API / User32.dll veya Python Pynput) dönüştür.
