<div align="center">

# 🌐 LingoFlow

**Ứng dụng Dịch Trực Tiếp (Live Overlay Translator) Siêu Tốc Cho Game, Manga, Anime & Tài Liệu**

*Dành cho Windows PC & Android Mobile • Tích hợp OCR Chuyên Dụng • Hỗ trợ DeepL & Google Translate*

---

[![Flutter](https://img.shields.io/badge/Flutter-3.47+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13+-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platforms-Windows%20%7C%20Android-4CAF50?style=for-the-badge&logo=windows&logoColor=white)](https://github.com)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20Architecture-FF6F00?style=for-the-badge)](https://github.com)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](LICENSE)

</div>

---

## 📖 Giới Thiệu

**LingoFlow** là giải pháp phần mềm mã nguồn mở giúp người dùng **dịch thuật theo thời gian thực (LIVE)** trực tiếp trên màn hình khi đang chơi game (Visual Novel, JRPG, game không hỗ trợ tiếng Việt), đọc truyện tranh (Manga, Manhua, Comic), hoặc xem tài liệu nước ngoài mà không cần phải chụp ảnh màn hình thủ công hay chuyển đổi qua lại giữa các cửa sổ ứng dụng.

Ứng dụng kết hợp giữa **C++ Win32 Native Desktop Engine** (Windows DWM Trong Suốt 100%, GDI Screen Capture, Global Hotkeys) và giao diện **Flutter Clean Architecture** hiện đại, mang lại hiệu năng cao, không gây tụt FPS khi chơi game.

---

## ✨ Tính Năng Nổi Bật

### 1. 🔍 Khung Dịch Nổi Toàn Màn Hình Trong Suốt 100% (Floating Lens)
- **Trong suốt tuyệt đối (Crystal Clear):** Sử dụng công nghệ DWM Per-Pixel Alpha của Windows, bên trong và ngoài khung hoàn toàn trong suốt, không làm mờ hay đổi màu màn hình bên dưới.
- **Kéo thả tự do (Draggable):** Chạm vào thanh tiêu đề để di chuyển khung đến bất kỳ vị trí nào trên màn hình máy tính.
- **Co giãn kích thước (Resizable):** Kéo góc dưới phải để phóng to/thu nhỏ khung vừa khít với bong bóng thoại truyện tranh hoặc phụ đề game.
- **Dịch tức thì & Live Scan:** Dịch 1 lần (`Alt + S`) hoặc bật chế độ quét tự động liên tục theo thời gian thực (`Alt + Q`).

### 2. ⚡ Bộ Máy Dịch Đa Nền Tảng (Multi-Engine Translation Hub)
- **Google Translate:** Tích hợp sẵn, tốc độ cao, miễn phí và không cần cấu hình API Key.
- **DeepL API:** Dành cho người dùng cần độ chính xác ngữ cảnh cao nhất cho Manga, Game và tiểu thuyết. Hỗ trợ cả tài khoản **DeepL Free** (`:fx`) và **DeepL Pro**.
- **Cơ chế Tự động Fallback:** Nếu DeepL gặp sự cố mạng hoặc hết hạn mức tháng, hệ thống tự động chuyển tiếp sang Google Translate để không làm gián đoạn trải nghiệm người dùng.

### 3. 🧠 Bộ Nhận Diện Chữ Viết Châu Á & Khử Nhiễu OCR
- **Asian OCR Engine 2:** Tối ưu hóa đặc trị nhận diện chữ tượng hình phức tạp: Tiếng Nhật (Kanji/Hiragana/Katakana), Tiếng Trung (Giản thể / Phồn thể), Tiếng Hàn (Hangul) và Tiếng Anh.
- **TextProcessor thông minh:**
  - Tự động khử ký tự rác từ OCR (`|`, `_`, `~`).
  - Nối liền các dòng chữ bị ngắt quãng bên trong bong bóng thoại Manga mà không làm vỡ cấu trúc câu CJK.
  - Chuẩn hoá ngoặc thoại tiếng Nhật `「...」`, `『...』`, `（...）`.
  - Tự động nối các từ tiếng Anh bị gạch nối ngắt dòng (ví dụ: `trans-\nlation` $\rightarrow$ `translation`).

### 4. 📖 Tra Cứu Từ Điển Tương Tác & Phát Âm Giọng Đọc AI (TTS)
- **Chế độ Tương Tác (`Alt + X`):** Chạm trực tiếp vào bất kỳ câu dịch nào trên màn hình để mở popup phân tích ngữ nghĩa chuyên sâu.
- **Phiên âm Furigana / Romaji / Pinyin:** Hỗ trợ người học ngoại ngữ dễ dàng đọc và hiểu cấu trúc từ vựng.
- **Phát âm AI (TTS Native Speaker 🔊):** Bấm nút loa để nghe giọng đọc bản xứ chuẩn xác của từng từ/câu.

### 5. ⭐ Sổ Từ Vựng & Xuất File Anki / Excel
- Tự động lưu trữ lịch sử các câu đã dịch với bộ lọc tìm kiếm tức thì.
- Đánh dấu sao ⭐ để lưu vào **Sổ Từ Vựng Yêu Thích**.
- **Xuất Dữ Liệu 1-Click:**
  - 📇 **Anki Flashcards (`.tsv`):** Định dạng chuẩn sẵn sàng import trực tiếp vào phần mềm học Anki.
  - 📊 **Excel / Bảng tính (`.csv`):** Quản lý từ vựng trên Notion, Google Sheets, Quizlet.
  - 📝 **Văn bản thuần (`.txt`):** Lưu trữ dạng danh sách dễ đọc.

### 6. 🎭 Tùy Biến Giao Diện Phụ Đề
- **4 Preset Phong Cách Phụ Đề:**
  - 🔵 *Cyberpunk Cyan (Mặc định)*: Viền Neon công nghệ, nền Slate tối.
  - 🟡 *Classic Cinema Yellow*: Chữ vàng phụ đề phim điện ảnh cổ điển có bóng đổ chống lóa.
  - ⚪ *Manga Balloon*: Nền trắng chữ đen phong cách truyện tranh.
  - ⚫ *Minimalist Dark*: Tối giản, thanh lịch.
- **2 Chế độ hiển thị vị trí:**
  - **In-place:** Gắn thẻ phụ đề đè ngay cạnh vị trí câu thoại gốc.
  - **Movie Subtitle Mode:** Gom toàn bộ phụ đề căn giữa đáy màn hình giống như xem phim rạp.

---

## ⌨️ Bảng Phím Tắt Toàn Cục (Global Hotkeys)

Các phím tắt hoạt động toàn hệ thống ngay cả khi bạn đang ở trong game toàn màn hình:

| Phím Tắt | Chức Năng | Mô Tả |
| :---: | :--- | :--- |
| **`Alt + Q`** | **Bật / Tắt Khung Dịch / Live Scan** | Mở nhanh Khung Dịch Nổi toàn màn hình hoặc tạm dừng quét. |
| **`Alt + S`** | **Chụp & Dịch 1 Lần (Single Shot)** | Chụp ngay tức thì vùng màn hình bên trong khung và dịch. |
| **`Alt + X`** | **Chuyển Chế Độ Xuyên Thấu / Tương Tác** | Bật/tắt chế độ click chuột xuyên qua app xuống game hoặc mở từ điển. |

---

## 🏗️ Kiến Trúc Dự Án (Clean Architecture)

Dự án được cấu trúc theo mô hình 4 tầng Clean Architecture chuẩn mực:

```text
E:\Github\LingoFlow/
├── lib/
│   ├── core/                        # Tiện ích dùng chung, mạng, hotkeys, dịch vụ
│   │   ├── constants/               # Bảng mã ngôn ngữ, cấu hình mặc định
│   │   ├── network/                 # Singleton Dio Client HTTP
│   │   ├── services/                # NativeOverlayService, HotkeyService, DictionaryService, TtsService, ExportService
│   │   └── utils/                   # TextProcessor, BmpEncoder
│   ├── domain/                      # Nghiệp vụ cốt lõi (Entities & Repository Interfaces)
│   │   ├── entities/                # TranslationItem, OcrResult, HistoryItem, TranslationEngine, SubtitleStyle
│   │   └── repositories/            # TranslationRepository, OcrRepository, HistoryRepository
│   ├── data/                        # Tầng dữ liệu (Data Sources & Repository Implementations)
│   │   ├── datasources/
│   │   │   ├── local/               # SharedPreferences History & Settings
│   │   │   └── remote/              # GoogleTranslateApi, DeepLApi, CloudOcrApi
│   │   └── repositories/            # TranslationRepositoryImpl, OcrRepositoryImpl, HistoryRepositoryImpl
│   ├── presentation/                # Giao diện người dùng & State Management (Riverpod)
│   │   ├── providers/               # SettingsProvider, OverlayProvider, HistoryProvider
│   │   ├── screens/                 # HomeScreen, SettingsScreen, OverlayScreen, HistoryScreen
│   │   └── widgets/                 # FloatingLens, MiniControlBar, DictionaryPopup, RegionSelector
│   └── main.dart                    # Entry Point ứng dụng
├── windows/
│   └── runner/                      # C++ Win32 Native Runner (DWM, BitBlt, MethodChannel)
├── android/                         # Nền tảng Android (Permissions, Foreground Service)
└── pubspec.yaml                     # Quản lý thư viện và cấu hình dự án
```

---

## 🚀 Hướng Dẫn Cài Đặt & Chạy Ứng Dụng

### 1. Yêu Cầu Môi Trường
- **Flutter SDK:** 3.47+ (Dart 3.13+)
- **Windows:** Windows 10/11 (Đã bật *Developer Mode* trong Windows Settings để hỗ trợ symlinks).
- **C++ Toolchain (Cho Windows Desktop):** Visual Studio 2022 hoặc *Visual Studio Build Tools* với workload `"Desktop development with C++"`.
- **Android SDK (Cho Mobile):** Android SDK 36, Build-Tools 35.0.0, NDK 28+.

---

### 2. Chạy Bản Windows Native Desktop (`.exe`)

1. **Di chuyển vào thư mục dự án:**
   ```powershell
   cd /d E:\Github\LingoFlow
   ```

2. **Chạy ở chế độ Debug:**
   ```powershell
   flutter run -d windows
   ```

3. **Biên dịch file chạy Release `.exe` độc lập:**
   ```powershell
   flutter build windows
   ```
   *File `.exe` thành phẩm sẽ nằm tại:* `build\windows\x64\runner\Release\lingo_flow.exe` *(bạn có thể click đúp chuột trực tiếp để mở app bất cứ lúc nào).*

---

### 3. Biên Dịch Bản Android Native (`.apk`)

1. **Biên dịch gói cài đặt APK:**
   ```powershell
   flutter build apk --debug
   ```
   *File `.apk` thành phẩm sẽ nằm tại:* `build\app\outputs\flutter-apk\app-debug.apk`

2. **Cài đặt:**
   - Sao chép file `app-debug.apk` vào điện thoại Android của bạn để cài đặt trực tiếp.
   - Hoặc kéo thả vào các trình giả lập Android (*LDPlayer, Nox, MuMu Player, BlueStacks*).

---

## 🛠️ Công Nghệ & Thư Viện Sử Dụng

- **Framework:** [Flutter](https://flutter.dev) & [Dart](https://dart.dev)
- **State Management:** [Riverpod 3.4+](https://riverpod.dev)
- **Networking:** [Dio](https://pub.dev/packages/dio)
- **Native Desktop Hooking:** C++ Win32 API, Desktop Window Manager (DWM), GDI BitBlt
- **Global Hotkeys:** [hotkey_manager](https://pub.dev/packages/hotkey_manager)
- **Window Management:** [window_manager](https://pub.dev/packages/window_manager), [screen_retriever](https://pub.dev/packages/screen_retriever)
- **Local Persistence:** [shared_preferences](https://pub.dev/packages/shared_preferences)
- **OCR Engine:** Win32 GDI Frame Capture + Multi-Language Cloud Asian OCR Engine 2
- **Translation APIs:** Google Translate Engine, DeepL Free/Pro API

---

## 📄 Bản Quyền (License)

Dự án được phân phối dưới giấy phép mã nguồn mở **MIT License**. Bạn hoàn toàn có thể tự do sử dụng, chỉnh sửa và đóng góp cho dự án.

---

<div align="center">
  <sub>Được phát triển với ❤️ cho cộng đồng game thủ và độc giả truyện tranh toàn cầu.</sub>
</div>
