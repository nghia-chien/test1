# Chức năng Tìm kiếm và Chat AI

## Tính năng mới đã thêm

### 1. Ô tìm kiếm thông minh
- **Vị trí**: Trang Home (`lib/pages/home_page.dart`)
- **Chức năng**: 
  - Nhập văn bản vào ô tìm kiếm
  - Nhấn Enter hoặc nút mũi tên để gửi
  - Tự động chuyển sang trang Chat AI với câu hỏi đã nhập

### 2. Cách sử dụng

#### Cách 1: Nhập và nhấn Enter
1. Mở ứng dụng
2. Đi đến trang Home
3. Tìm ô tìm kiếm với placeholder "Gợi ý phong cách?"
4. Nhập câu hỏi của bạn (ví dụ: "Tôi nên mặc gì cho buổi hẹn hò?")
5. Nhấn Enter trên bàn phím
6. Ứng dụng sẽ chuyển sang trang Chat AI và tự động gửi câu hỏi

#### Cách 2: Nhập và nhấn nút mũi tên
1. Nhập câu hỏi vào ô tìm kiếm
2. Nhấn vào nút mũi tên màu xanh bên phải
3. Ứng dụng sẽ chuyển sang trang Chat AI và tự động gửi câu hỏi

### 3. Các thay đổi kỹ thuật

#### Trong `home_page.dart`:
- Thêm `onSubmitted` callback cho TextField
- Thêm `onPressed` logic cho nút mũi tên
- Thêm hàm `_navigateToChatWithQuery()` để chuyển trang
- Tự động xóa nội dung ô tìm kiếm sau khi chuyển trang

#### Trong `chat_screen.dart`:
- Thêm tham số `initialMessage` cho constructor
- Thêm logic trong `initState()` để tự động gửi tin nhắn đầu tiên
- Cập nhật tất cả các nơi gọi `ChatScreen` để phù hợp với constructor mới

### 4. Ví dụ sử dụng

**Câu hỏi mẫu bạn có thể thử:**
- "Tôi nên mặc gì cho buổi hẹn hò?"
- "Phong cách casual cho cuối tuần?"
- "Màu sắc phù hợp với da tôi?"
- "Outfit cho dự tiệc?"
- "Cách mix đồ với áo khoác denim?"

### 5. Lưu ý
- Ô tìm kiếm chỉ hoạt động khi có nội dung (không rỗng)
- Sau khi chuyển sang Chat AI, ô tìm kiếm sẽ được xóa sạch
- Chat AI sẽ tự động gửi câu hỏi và chờ phản hồi
- Bạn có thể tiếp tục trò chuyện bình thường trong Chat AI

## Cách test
1. Chạy ứng dụng: `flutter run`
2. Đi đến trang Home
3. Thử nhập một câu hỏi vào ô tìm kiếm
4. Nhấn Enter hoặc nút mũi tên
5. Kiểm tra xem có chuyển sang Chat AI và tự động gửi tin nhắn không 