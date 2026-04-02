# Dikte Özelliği (Speech-to-Text) - Masaüstü Geliştiricisi Rehberi

## Tanıtım
Mobil uygulamamızdaki "Trackpad" ekranına sol alt köşeye bir Mikrofon (Dikte) tuşu eklenmiştir. Kullanıcı bu butona basılı tuttuğunda veya tıkladığında, cihazın kendi yerel ses motoru (Speech-to-Text) aracılığı ile çevredeki konuşma dinlenmeye başlanır. 

## Kısmi ve Nihai (Partial vs Final) Aktarım Kararı
Normal şartlarda STT motorları "mer", "merha", "merhaba" şeklinde *kısmi* geri bildirimler de verirler. Ancak klavye simülatörü kodlamanızı (Desktop tarafında backspace tuşu basma karmaşıklığını) hafifletmek için bu motorun sadece **FINAL (`is_final: true`)** (cümle sona erdiğinde veya nefes alındığında oluşan) kesin bloklarını masaüstüne yollama kararı aldık. Böylece sizin yapmanız gereken tek şey, gelen paketteki metni standart bilgisayar klavyesinden yazıyormuş gibi işletim sistemine ("Keystroke/Submit") göndermektir.

## Protokol / İletişim Verisi
Dikte işlemi, verinin kesin olarak ulaşması ve sıralı gitmesi gerektiği için (Lossless) **WebSocket (TCP)** üzerinden gönderilir. UDP dinleyicisinde bu işlemi beklemenize gerek yoktur. 

### Payload Yapısı (JSON)
Mesajlar geldiğinde, `t` parametresi "DICT" (Dictation) olarak setlenmiştir.

```json
{
  "t": "DICT",
  "text": "Bugün hava çok güzel.",
  "is_final": true
}
```

### Masaüstü Tarafından İşlenmesi

- Eğer `t == "DICT"` olan bir paket aldıysanız.
- İlgili JSON paketindeki `text` özelliğini alıp bilgisayarda sıradaki karakterleri ilgili input (metin alanı) alanına *klavye tuş vuruşu* gibi yazdırmalısınız.
- Kullanıcının cihaz/dil tercihleri tamamen mobil tarafında halledildiği için size sadece "UTF-8 karakter dizgisi" (string) gelecektir.
- Çoğu sistemde bu metnin ardına "boşluk" (Space) koyarak diğer gönderilecek pakete hazır etmek pratik bir yöntemdir (çünkü ardı ardına 2 final pakette konuşma boşlukları eksik kalabilir).
