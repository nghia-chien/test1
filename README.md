# Ứng dụng Quản lý Trang phục

## Mô tả

Đây là một ứng dụng Flutter giúp người dùng quản lý tủ đồ cá nhân, tạo outfits, và nhận gợi ý từ AI. Ứng dụng tích hợp các tính năng như lịch, lịch sử hoạt động, chat, và thông báo, với backend được hỗ trợ bởi Firebase.

## Tính năng chính

- **Tủ đồ (Closet)**: Quản lý các món đồ trong tủ đồ của bạn.
- **Tạo Outfit**: Tạo và lưu các bộ trang phục.
- **AI Mix**: Nhận gợi ý trang phục từ trí tuệ nhân tạo.
- **Lịch (Calendar)**: Lên lịch cho các hoạt động liên quan đến trang phục.
- **Lịch sử hoạt động (Activity History)**: Theo dõi lịch sử các hoạt động.
- **Chat**: Giao tiếp với người dùng khác hoặc AI.
- **Thông báo (Notifications)**: Nhận thông báo về các sự kiện.
- **Feed**: Xem và chia sẻ outfits với cộng đồng.
- **Hồ sơ (Profile)**: Quản lý thông tin cá nhân.
- **Đăng nhập/Đăng ký**: Xác thực người dùng qua Firebase.

## Yêu cầu hệ thống

- Flutter SDK: >= 3.0.0
- Dart SDK: >= 2.19.0
- Android Studio hoặc VS Code với Flutter extension
- Firebase account để cấu hình backend

## Cài đặt

1. **Clone repository:**
   ```bash
   git clone <repository-url>
   cd test1
   ```

2. **Cài đặt dependencies:**
   ```bash
   flutter pub get
   ```

3. **Cấu hình Firebase:**
   - Tạo dự án Firebase tại [Firebase Console](https://console.firebase.google.com/).
   - Thêm file `google-services.json` vào thư mục `android/app/`.
   - Thêm file `GoogleService-Info.plist` vào thư mục `ios/Runner/`.
   - Cập nhật `firebase_options.dart` nếu cần.

4. **Cấu hình backend functions (nếu có):**
   - Di chuyển vào thư mục `functions/`:
     ```bash
     cd functions
     npm install
     ```
   - Triển khai functions lên Firebase:
     ```bash
     firebase deploy --only functions
     ```

## Chạy ứng dụng

1. **Chạy trên Android/iOS:**
   ```bash
   flutter run
   ```

2. **Chạy trên Web:**
   ```bash
   flutter run -d chrome
   ```

3. **Chạy tests:**
   ```bash
   flutter test
   ```

## Cấu trúc dự án

```
lib/
├── constants/
│   └── constants.dart          # Các hằng số của ứng dụng
├── models/
│   ├── activity_history.dart   # Model cho lịch sử hoạt động
│   ├── chat_message.dart       # Model cho tin nhắn chat
│   ├── clothing_item.dart      # Model cho món đồ
│   └── outfit.dart             # Model cho outfit
├── pages/
│   ├── ai_mix_page.dart        # Trang AI mix
│   ├── calendar_page.dart      # Trang lịch
│   ├── chat_screen.dart        # Màn hình chat
│   ├── closet_page.dart        # Trang tủ đồ
│   ├── clothing_detail_page.dart # Chi tiết món đồ
│   ├── CreateOutfitPage.dart   # Tạo outfit
│   ├── feed_page.dart          # Trang feed
│   ├── history_page.dart       # Trang lịch sử
│   ├── home_page.dart          # Trang chủ
│   ├── login_page.dart         # Trang đăng nhập
│   ├── main_screen.dart        # Màn hình chính
│   ├── notification.dart       # Trang thông báo
│   ├── outfit_detail_page.dart # Chi tiết outfit
│   ├── profile_page2.dart      # Trang hồ sơ
│   ├── question_page.dart      # Trang câu hỏi
│   ├── register_pages.dart     # Trang đăng ký
│   └── uploadimage_page.dart   # Upload ảnh
├── services/
│   ├── activity_history_service.dart # Service cho lịch sử hoạt động
│   ├── chat_service.dart       # Service cho chat
│   ├── location_service.dart   # Service cho vị trí
│   └── weather_service.dart    # Service cho thời tiết
└── utils/
    ├── color_updater.dart      # Cập nhật màu sắc
    └── responsive_helper.dart  # Helper responsive
```

## Công nghệ sử dụng

- **Flutter**: Framework chính cho phát triển ứng dụng đa nền tảng.
- **Dart**: Ngôn ngữ lập trình.
- **Firebase**: Backend as a Service (Authentication, Firestore, Storage, Functions).
- **Provider**: Quản lý trạng thái.
- **HTTP**: Gọi API.

## Đóng góp

Chúng tôi hoan nghênh mọi đóng góp! Vui lòng:

1. Fork repository.
2. Tạo branch mới cho tính năng của bạn (`git checkout -b feature/AmazingFeature`).
3. Commit thay đổi (`git commit -m 'Add some AmazingFeature'`).
4. Push lên branch (`git push origin feature/AmazingFeature`).
5. Tạo Pull Request.

## Giấy phép

Dự án này được phân phối dưới giấy phép MIT. Xem file `LICENSE` để biết thêm chi tiết.

## Liên hệ

Nếu bạn có câu hỏi hoặc cần hỗ trợ, vui lòng liên hệ qua email: your-email@example.com

---

*Được phát triển với ❤️ bởi [Tên của bạn]*
