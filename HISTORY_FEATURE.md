# Tính năng History - Lịch sử hoạt động

## Tổng quan
Tính năng History cho phép người dùng theo dõi và xem lại tất cả các hoạt động của mình trong ứng dụng. Mỗi hoạt động sẽ được lưu trữ với thông tin chi tiết và có thể được lọc theo loại hoạt động.

## Các loại hoạt động được theo dõi

### 1. Upload (Đăng bài/Tải lên)
- **Khi nào**: Khi người dùng đăng bài viết hoặc tải lên trang phục
- **Thông tin lưu**: Nội dung bài viết, ảnh, thông tin trang phục
- **Vị trí tracking**: 
  - `feed_page.dart` - đăng bài viết
  - `uploadimage_page.dart` - tải lên trang phục

### 2. Like (Thích)
- **Khi nào**: Khi người dùng thích hoặc bỏ thích bài viết
- **Thông tin lưu**: Tên người đăng bài, loại hành động (like/unlike)
- **Vị trí tracking**: `feed_page.dart`

### 3. Comment (Bình luận)
- **Khi nào**: Khi người dùng bình luận bài viết
- **Thông tin lưu**: Nội dung bình luận, tên người đăng bài
- **Vị trí tracking**: `feed_page.dart`

### 4. Chat (Trò chuyện với AI)
- **Khi nào**: Khi người dùng gửi tin nhắn cho AI
- **Thông tin lưu**: Nội dung tin nhắn
- **Vị trí tracking**: `chat_screen.dart`

### 5. Calendar (Lịch)
- **Khi nào**: Khi người dùng thêm sự kiện vào lịch
- **Thông tin lưu**: Tên sự kiện, thời gian, ngày
- **Vị trí tracking**: `calendar_page.dart`

### 6. Profile (Hồ sơ)
- **Khi nào**: Khi người dùng cập nhật thông tin hồ sơ
- **Thông tin lưu**: Tên mới, bio mới
- **Vị trí tracking**: `profile_page.dart`

## Cấu trúc dữ liệu

### ActivityHistory Model
```dart
class ActivityHistory {
  final String id;
  final String userId;
  final String action;
  final String description;
  final String? imageUrl;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
}
```

### Firestore Collection: `activity_history`
```json
{
  "userId": "user_id",
  "action": "upload|like|comment|chat|calendar|profile",
  "description": "Mô tả hoạt động",
  "imageUrl": "base64_image_or_url",
  "timestamp": "timestamp",
  "metadata": {
    // Thông tin bổ sung tùy theo loại hoạt động
  }
}
```

## Tính năng của trang History

### 1. Xem danh sách hoạt động
- Hiển thị tất cả hoạt động theo thứ tự thời gian
- Mỗi hoạt động có icon và màu sắc riêng
- Hiển thị thời gian tương đối (vừa xong, 5 phút trước, etc.)

### 2. Lọc hoạt động
- Filter chips để lọc theo loại hoạt động
- Hiển thị số lượng hoạt động cho mỗi loại
- Có thể xem tất cả hoặc từng loại riêng biệt

### 3. Thống kê
- Tab thống kê hiển thị tổng số hoạt động
- Phân tích theo loại hoạt động
- Biểu đồ trực quan

### 4. Quản lý
- Xóa từng hoạt động riêng lẻ
- Xóa tất cả hoạt động
- Popup menu cho mỗi hoạt động

## Cách sử dụng

### Truy cập trang History
1. Mở ứng dụng
2. Vào trang Home
3. Nhấn vào nút "History" (icon lịch sử)

### Xem hoạt động
- Tab "Tất cả": Xem tất cả hoạt động
- Tab "Thống kê": Xem thống kê tổng quan
- Sử dụng filter chips để lọc theo loại

### Quản lý hoạt động
- Nhấn vào menu 3 chấm bên cạnh hoạt động để xóa
- Nhấn icon thùng rác trên thanh công cụ để xóa tất cả

## Tích hợp vào ứng dụng

### 1. Import service
```dart
import '../services/activity_history_service.dart';
```

### 2. Thêm activity tracking
```dart
await ActivityHistoryService.addActivity(
  action: 'action_type',
  description: 'Mô tả hoạt động',
  imageUrl: 'optional_image_url',
  metadata: {
    // Thông tin bổ sung
  },
);
```

### 3. Navigation
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const HistoryPage()),
);
```

## Lưu ý kỹ thuật

### Performance
- Giới hạn 50 hoạt động gần nhất cho mỗi user
- Sử dụng Stream để real-time updates
- Lazy loading cho danh sách dài

### Security
- Chỉ user có thể xem hoạt động của chính mình
- Validation dữ liệu trước khi lưu
- Error handling cho các trường hợp lỗi

### UI/UX
- Responsive design cho mobile và tablet
- Loading states và error handling
- Empty states khi chưa có hoạt động
- Smooth animations và transitions

## Tương lai

### Tính năng có thể thêm
1. Export history ra file
2. Tìm kiếm trong history
3. Phân tích xu hướng hoạt động
4. Notifications cho hoạt động quan trọng
5. Backup và restore history

### Cải tiến
1. Thêm biểu đồ thống kê chi tiết
2. Filter theo khoảng thời gian
3. Group activities theo ngày/tuần/tháng
4. Share activity với bạn bè 