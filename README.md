# ♻️ Geri Dönüşüm Mobil Uygulaması

Yapay zekâ destekli çevre dostu mobil uygulama: Atıkları tanı, puan kazan, çevreye katkıda bulun!  
Flutter & Firebase tabanlı bu uygulama, geri dönüşüm bilincini artırmayı amaçlayan yenilikçi bir çözümdür.

---

## 🚀 Özellikler

- 📷 **Atık Fotoğrafı Çekme:** Uygulama içerisinden atıkların fotoğrafı çekilir.
- 🧠 **AI Tabanlı Atık Sınıflandırma:** Google Gemini Vision API sayesinde atıklar 8 sınıfa ayrılır:  
  _Plastik, Kağıt, Cam, Metal, Organik, Elektronik, Tehlikeli, Diğer_
- 🪙 **Puanlama Sistemi:** Her doğru sınıflandırma için kullanıcıya puan kazandırılır.
- 🏅 **Rozet Kazanımı:** Belirli puan eşiği geçildiğinde rozetler otomatik tanımlanır.
- 📍 **En Yakın Geri Dönüşüm Noktaları:** Kullanıcının konumuna göre en yakın çöp kutuları listelenir.
- 📊 **Haftalık & Aylık İstatistikler:** Pie chart, bar chart ve line chart destekli görsellerle veri analizi.
- 🌗 **Karanlık Mod Desteği:** Göz yormayan kullanıcı arayüzü.
- 🔒 **Firebase Authentication:** E-posta ve şifre ile güvenli kullanıcı yönetimi.
- ☁️ **Firestore Entegrasyonu:** Gerçek zamanlı veri kaydı ve senkronizasyon.
- ✉️ **Otomatik Bildirimler:** İlerleme durumuna göre kullanıcı bilgilendirmeleri.

---

## 🧑‍💻 Teknolojiler

| Katman | Teknoloji |
|--------|-----------|
| UI | Flutter (Material 3, Responsive UI, Animasyonlar) |
| Backend | Firebase Firestore, Firebase Authentication |
| AI | Google Gemini Vision API |
| State Management | Provider / Riverpod |
| Bildirim | Firebase Cloud Functions / Twilio (opsiyonel) |
| Harita & Lokasyon | `geolocator`, `google_maps_flutter` |
