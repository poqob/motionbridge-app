
---

## BÖLÜM 1: Frontend Geliştirici El Kitabı (The Apple-Standard)

Bu doküman, Flutter tarafındaki geliştiricinin uygulamayı hangi standartlarda inşa etmesi gerektiğini açıklar.

### 1. Mimari ve Klasör Yapısı (Feature-First)
Her yeni kontrolcü (Trackpad, Joystick vb.) kendi klasöründe yaşamalıdır. Logic ve UI kesinlikle ayrılmalıdır.
*   **Kural:** `StateNotifier` sadece veri işler ve socket'e paket gönderir. Widget'lar sadece `ref.watch` ile durumu izler.

### 2. "Invisible Interface" UX Prensipleri
*   **Haptik Geri Bildirim:** Her etkileşimde fiziksel bir karşılık olmalı. 
    *   *Trackpad:* Tıklama simülasyonu için `HapticFeedback.mediumImpact()`.
    *   *Dimmer:* Her %5'lik değişimde `HapticFeedback.lightImpact()`.
*   **Motion & Fluidity:** UI asla statik kalmamalı. `AnimatedContainer` veya `Implicit Animations` kullanarak geçişleri yumuşatın. `Curves.easeOutExpo` Apple hissiyatı için en iyi tercihtir.
*   **Sıfır Gecikme Yanılsaması:** Paket ağa gönderilmeden önce UI güncellenmeli (Optimistic UI).

### 3. Pro-Tip: "Velocity & Inertia" (Eylemsizlik)
Bir trackpad'de parmağınızı hızla kaydırıp bıraktığınızda imleç aniden durmaz. Flutter'daki `onPanEnd` içindeki `velocity` değerini alıp, masaüstüne sönümlenen paketler göndermeye devam eden bir **Inertia Engine** yazmalısın. Bu, uygulamayı "ucuz bir kumanda" olmaktan çıkarıp "profesyonel bir çevre birimi" seviyesine taşır.

---

## BÖLÜM 2: MotionBridge İletişim Protokolü (MBP)

Cihazların birbirini bulması ve veri transferi için **UDP** (Keşif) ve **TCP/WebSocket** (Komut) hibrit yapısını kullanacağız.

### 1. Cihaz Keşif Aşaması (UDP Broadcast)
Eşleşme gerçekleşmediyse, mobil uygulama yerel ağdaki tüm cihazlara bir "Arayış" paketi gönderir.

*   **Broadcast Port:** 53535 (Örnek)
*   **Mobil Yayın (Client Hello):**
    ```json
    {
      "event": "DISCOVERY_REQUEST",
      "payload": { "device_name": "iPhone 15 Pro", "app_version": "1.0.0" }
    }
    ```
*   **Servis Yanıtı (Server Pong):**
    ```json
    {
      "event": "DISCOVERY_RESPONSE",
      "payload": {
        "server_name": "Workstation-PC",
        "ip": "192.168.1.42",
        "port": 8080,
        "os": "Windows"
      }
    }
    ```

### 2. Veri Formatı (Action-Based JSON)
Bağlantı kurulduktan sonra gönderilecek paketler mümkün olduğunca küçük tutulmalıdır. Key isimleri tek karakter veya kısa tutulabilir.

#### A. Trackpad / Mouse Hareketi
```json
{
  "t": "MOVE",
  "dx": 12.5,
  "dy": -4.2,
  "btn": 0 // 0: None, 1: Left, 2: Right
}
```

#### B. Dimmer (Ortam Kontrolü)
```json
{
  "t": "DIM",
  "v": 0.75, // 0.0 ile 1.0 arası
  "target": "BRIGHTNESS" // veya "VOLUME"
}
```

#### C. Joystick (Oyun/Navigasyon)
```json
{
  "t": "JOY",
  "x": 0.9,
  "y": -0.1,
  "angle": 45
}
```

### 3. Ağ Katmanı Stratejisi
*   **Düşük Gecikme:** Trackpad ve Joystick gibi sürekli veri akışı gerektiren özellikler için **UDP** kanalı açık tutulmalıdır. Paket kaybı, gecikmeden daha tolere edilebilirdir.
*   **Güvenilirlik:** Dimmer veya Tuş atamaları (Magic Mouse gesture'ları) için **TCP (WebSocket)** kullanılmalıdır; çünkü bu komutların ulaştığından emin olmalıyız.

---

### Proje Dosya Yapısı Önerisi (Flutter)

```text
lib/
├── constants/
│   ├── app_haptics.dart      # Merkezi haptik yönetim extension'ları
│   └── app_theme.dart        # M3 Dark/Light tanımları
├── features/
│   ├── discovery/            # UDP Broadcast ve Sunucu Listeleme
│   │   ├── logic/            # discovery_provider.dart
│   │   └── ui/               # scanning_screen.dart
│   ├── trackpad/             # Mouse ve Gesture kontrolleri
│   │   ├── logic/            # trackpad_provider.dart (Inertia logic burada)
│   │   └── ui/               # trackpad_view.dart
│   └── environment/          # Dimmer ve Akıllı Kontroller
│       ├── logic/            # dimmer_provider.dart
│       └── ui/               # dimmer_widget.dart
├── utils/
│   └── network_manager.dart  # Socket ve UDP yönetimi (Singleton)
└── main.dart                 # ProviderScope ve Global Init
```
