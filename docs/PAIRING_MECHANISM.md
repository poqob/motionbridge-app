# MotionBridge Yeni Cihaz Eşleşme (Pairing) Süreci ve Web-Socket API Kontratı Değişiklikleri

Masaüstü ile kumanda (mobil) arasındaki eşleşme sistemini çok daha güvenli bir Challenge-Response (Meydan Okuma-Yanıt) mimarisine geçirdik. Masaüstü uygulamamız artık ağda kendisini yayınlayacak ve bağlantılar rastgele bir kod (token) doğrulamasından geçerek kurulacak. 

Aşağıdaki adımlara ve JSON kontratlarına göre entegrasyonu sağlamanız gerekmektedir:

## Yeni Pairing (Eşleşme) Akışı

### 1. Dinleme ve Keşif (Discovery)
Masaüstü yazılımımız her 2 saniyede bir yerel ağda **UDP Port 44446** üzerinden kendini duyuran bir Broadcast paketi gönderir.
Kumanda tarafında bu portu dinleyerek ağdaki kullanılabilir masaüstü cihazlarını keşfetmelisiniz.

**Alacağınız Paket Örneği:** 
```json
{
  "type": "host_announcement",
  "host_name": "Kullanici-PC",
  "data_port": 44444,
  "ws_port": 44445
}
```

### 2. Bağlantı İsteği Gönderme (Connection Request)
Kullanıcı arayüzünde bulduğu bir PC'ye tıklayıp bağlanmak istediğinde, masaüstü makinenin IP'sine ve `ws_port` (WebSocket) portuna bağlanmalısınız. Bağlantı açılır açılmaz şu payload'u yollamalısınız:

**Gönderilecek Paket:**
```json
{
  "type": "connection_request",
  "device_id": "UNIQUE-DEVICE-UUID-1234",
  "device_name": "iPhone 13 / Samsung S23 vb."
}
```
*Önemli Not:* Bu aşamadan sonra masaüstünden yanıt beklemenizi sağlayan bir bekleme (loading) UI'ı göstermelisiniz. Çünkü masaüstü kullanıcısının arayüzden onay vermesi gerekmektedir.

### 3. Masaüstünün Kabul/Ret Etmesi
Masaüstündeki kullanıcının aksiyonuna göre WebSocket üzerinden iki tip geri dönüş alabilirsiniz.

**Eğer kullanıcı isteğinizi reddederse:**
```json
{
  "type": "connection_rejected",
  "reason": "User declined"
}
```

**Eğer kullanıcı kabul ederse:** Sistem size **sadece sizin cihazınız için üretilmiş tek kullanımlık bir eşleşme kodu (pairing_code)** gönderecektir:
```json
{
  "type": "connection_accepted",
  "pairing_code": "123456"
}
```

### 4. Kodu Geri Gönderme ve Doğrulama (Pairing Request)
Kabul mesajını ve `pairing_code` değerini aldıktan hemen sonra (arka planda kullanıcıya hissettirmeden otomatik olarak), masaüstüne bu kodu onayladığınızı belirten eşleşme isteğini yapmalısınız. **Eğer bu adımı yapmazsanız eşleşme tamamlanmaz.**

**Gönderilecek Paket:**
```json
{
  "type": "pairing_request",
  "device_id": "UNIQUE-DEVICE-UUID-1234",
  "pairing_code": "123456"
}
```

### 5. Eşleşme Tamamlanması
Gönderdiğiniz kod masaüstünde doğru doğrulanırsa, son olarak aşağıdaki başarılı paketi alacaksınız ve cihaz masaüstünde kalıcı olarak kayıt edilmiş olacak.

**Alınacak Paket:**
```json
{
  "type": "pairing_success"
}
```

*Not:* Bu mesajı aldıktan sonra eşleşmenin tamamlandığını kullanıcıya göstererek normal kullanım ekranlarına (Fare/Klavye kontrolü tarafına) geçiş yapabilirsiniz. Bu aşamadan itibaren IP adresiniz sistemde yetkilendirilmiş ("Authorization") olarak kalacaktır. Artık diğer eventleri göndermeye başlayabilirsiniz.

---
**Özet Akış:**
1. (UDP) Host'u keşfet.
2. (WS) `connection_request` gönder -> Bekle.
3. (WS) `connection_accepted` bekle, içinden `pairing_code`u al.
4. (WS) `pairing_request` gönder (kodu geri yolla).
5. (WS) `pairing_success` görünce yetkilendin, normal kullanıma geç.