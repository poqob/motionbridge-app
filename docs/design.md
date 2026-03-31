
---

# `design.md` - MotionBridge Görsel Kimlik ve UX Rehberi

## 1. Tasarım Felsefesi: "The Ethereal Bridge"
Uygulama, kullanıcının elinde ağırlığı olmayan, ışık ve doku üzerine kurulu bir katman gibi hissedilmelidir. Karmaşık menüler yerine, buzlu cam (Glassmorphism) üzerinde süzülen minimal düğümler (Nodes) kullanılacaktır.

## 2. Renk Paleti (Color Tokens)
| Element | Renk Kodu | Kullanım Amacı |
| :--- | :--- | :--- |
| **Surface (Zemin)** | `#FFFFFF` | Saf beyaz, nefes alan boşluklar. |
| **Glass (Katman)** | `RGBA(245, 240, 230, 0.4)` | Hafif sepya tonlu, buzlu cam efekti. |
| **Primary (Nodelar)** | `#4A4238` | Derin sepya-gri. Bağlantı çizgileri ve ana metinler. |
| **Accent (Aktif)** | `#D4C9B5` | Yumuşak altın-sepya. Seçili durumlar için. |
| **Shadow (Derinlik)** | `RGBA(0, 0, 0, 0.03)` | Çok hafif, doğal ortam gölgeleri. |

## 3. Tipografi ve Hiyerarşi
*   **Font:** Inter veya SF Pro (Apple Standard).
*   **Headline:** `FontWeight.w900`, `letterSpacing: 2.0`. Tüm başlıklar Büyük Harf (Caps).
*   **Labels:** `FontWeight.w300`, `color: Colors.grey.withOpacity(0.6)`.

## 4. Bileşen Standartları (UI Components)

### A. GlassCard (Buzlu Cam Panel)
Her kontrolcü (Trackpad, Dimmer) bir `GlassCard` içinde yaşar.
*   **Blur:** `BackdropFilter(filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15))`.
*   **Kenarlık:** `Border.all(color: Colors.white.withOpacity(0.2), width: 0.5)`.
*   **Şekil:** `BorderRadius.circular(32)`.

### B. The Connectivity Graph (Navigasyon)
Ana ekranda cihazlar arasındaki bağlantı, statik bir ikon yerine canlı bir grafik olarak görünür.
*   **Etkileşim:** Telefon hareket ettikçe (Gyroscope), arka plandaki sepyalı bağlantı çizgileri hafifçe kayar (Parallax).

## 5. Kritik UX Direktifleri (Pro-Level)

### I. Haptic Feedback Map
*   **Trackpad Tap:** `HapticFeedback.mediumImpact()`.
*   **Dimmer Değişimi:** Her %10'luk dilimde `HapticFeedback.lightImpact()`.
*   **Bağlantı Kuruldu:** `HapticFeedback.vibrate()` (Kısa ve öz).

### II. Motion (Akışkanlık)
*   **Giriş Animasyonu:** Uygulama açıldığında elemanlar ekrana `opacity: 0`dan `1`e, aşağıdan yukarıya doğru `Curves.easeOutExpo` ile süzülerek gelmeli.
*   **Geçişler:** Sayfa değişimlerinde `Hero` widget'ı ile bağlantı düğümleri (Nodes) bir sonraki ekrana taşınmalı.

## 6. Dosya Yapısı (Feature-First)
```text
lib/
├── constants/
│   ├── app_colors.dart      # Sepya ve Beyaz tanımları
│   └── app_styles.dart      # Glassmorphism dekorasyonları
├── features/
│   ├── controller/
│   │   ├── logic/           # Hareket verisi işleme
│   │   └── ui/
│   │       ├── widgets/
│   │       │   ├── glass_trackpad.dart
│   │       │   └── sepya_dimmer.dart
│   │       └── control_screen.dart
│   └── discovery/           # Cihaz bulma ekranı (Modern Graph UI)
└── utils/
    └── haptic_helper.dart   # Merkezi haptik yönetimi
```

---

### 💡 Pro Tip: "The Ambient Shadow"
Uygulamanın gerçekten "Apple-quality" hissetmesi için `GlassCard` bileşenlerinin gölgelerini statik bırakma. Telefonun `accelerometer` verisini kullanarak gölgenin yönünü (`BoxShadow` offset), telefonun tutuş açısına göre milimetrik olarak değiştir. Bu, kullanıcının gözünde arayüzün ekranda "yüzdüğü" illüzyonunu mükemmelleştirir.

---
