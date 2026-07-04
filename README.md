# RoadAI 🛡️ — Yol Öfkesi Analizörü ve Sakinleştirici Asistan

Sürücünün **yüz ifadesi**, **ses tonu** ve **hız** verilerinden duygusal durumunu
gerçek zamanlı analiz eden; öfke, stres veya yorgunluk anlarında **müzik**,
**nefes egzersizi**, **mola önerisi** gibi müdahalelerle sakinleştiren Flutter
uygulaması. Teknik tasarım dokümanı (Sürüm 2.0) temel alınarak geliştirildi.

## Özellikler

- 📷 **Gerçek sürüş modu** (Android/iOS): ön kamera + Google ML Kit ile cihaz
  üzerinde yüz analizi (gülümseme, göz kapanması → yorgunluk), mikrofon RMS
  enerjisi ile ses analizi, GPS ile hız. **Görüntü/ses asla buluta gitmez (Edge AI).**
- 🎬 **Demo senaryoları**: dokümandaki 3 gerçek zamanlı senaryo (trafik öfkesi,
  uzun yol yorgunluğu, stresli toplantı) + serbest mod — kamera olmadan tam deneyim.
- 🧠 **Karar Destek Sistemi (KDS)**: kural tabanlı motor (örn. öfke > %80 VE
  hız > 90 km/s → yavaşla uyarısı) + öğrenme tabanlı motor (👍/👎 geri
  bildirimiyle kişiselleşen eşikler) + müdahale bekleme süreleri.
- 🎵 **Gömülü müzik terapisi**: 8 telifsiz parça (sakinleştirici / meditasyon /
  enerjik), çevrimdışı çalışır, müdahale anında otomatik başlar.
- 🧘 **4-7-8 nefes egzersizi**: animasyonlu daire, Türkçe sesli rehber (TTS),
  titreşim, döngü sayacı.
- 📊 **Raporlar**: Sakin Sürüş Puanı (0-100), duygu dağılımı, haftalık grafik,
  müdahale istatistikleri, sürüş geçmişi + detay ekranı, rozetler.
- ⚙️ **Ayarlar**: profil, müdahale tercihleri, hassasiyet, sesli uyarı/titreşim,
  verileri silme (KVKK/GDPR).
- 🗣️ Türkçe sesli asistan, tamamen Türkçe arayüz, karanlık "gece sürüşü" teması.

## Çalıştırma

```bash
flutter pub get

# Android (tam deneyim: kamera + ML Kit + GPS + mikrofon)
flutter run -d android

# Web (demo senaryoları + tüm ekranlar; ML Kit web'de benzetimle çalışır)
flutter run -d chrome
```

> **Windows'ta Gradle "Unable to establish loopback connection" hatası alırsanız:**
> geçici dizini kısa bir yola yönlendirin:
> `set TEMP=C:/projects/roadai/build/jtmp` ve `set GRADLE_OPTS=-Djava.io.tmpdir=C:/projects/roadai/build/jtmp`

## Arkadaşa Test İçin Gönderme

Hazır APK'lar `build/app/outputs/flutter-apk/` altında:

- **`app-arm64-v8a-release.apk` (85 MB)** → modern telefonların tamamı; bunu gönderin.
- `app-armeabi-v7a-release.apk` → çok eski cihazlar için.

Kurulum: APK'yı WhatsApp/Drive ile gönderin → telefonda açın → "Bilinmeyen
kaynaklardan yükleme"ye izin verin → kurun. İlk sürüşte kamera/mikrofon/konum
izinlerini onaylayın.

> Not: APK'lar test için debug anahtarıyla imzalı. Play Store'a yüklemeden önce
> kendi keystore'unuzla imzalayın (`android/app/build.gradle.kts` → signingConfig).

Yeniden üretmek için: `flutter build apk --release --split-per-abi`

## Mimari

```
lib/
├── models/        # EmotionType, EmotionSample, DriveSession, InterventionEvent
├── services/      # face_engine (ML Kit), voice_engine (RMS), speed_service (GPS),
│                  # decision_engine (KDS), simulation_engine, tts, storage (Hive)
├── controllers/   # drive_controller (multimodal füzyon + oturum), music, settings
├── screens/       # splash, onboarding, dashboard, breathing, reports, music, settings
└── widgets/       # emotion_aura, calm_ring, sparkline, intervention_banner
```

Veri tamamen yerel: Hive (oturumlar, ayarlar, KDS eşik öğrenmeleri).

## Testler

```bash
flutter test   # KDS puanlama, serileştirme, simülasyon motoru testleri
```

## Müzik Lisansları

Tüm parçalar: **Kevin MacLeod (incompetech.com)** — Creative Commons: By
Attribution 4.0 (https://creativecommons.org/licenses/by/4.0/). Atıf uygulama
içinde Ayarlar → Hakkında bölümünde de yer alır.
