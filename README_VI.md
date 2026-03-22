# prm393_project — Flutter + Firebase (Bản Tiếng Việt)

## Giới thiệu nhanh (TL;DR)

- **Ứng dụng**: Nền tảng di động Flutter để khám phá và đặt phòng theo giờ, hỗ trợ các phân quyền (Người dùng / Chủ phòng / Quản trị viên).
- **Backend**: Firebase (Auth + Firestore + Cloud Messaging). Các dịch vụ hỗ trợ: Cloudinary (quản lý hình ảnh), Vietnam Provinces API (dữ liệu hành chính).
- **Tài liệu**: Hướng dẫn cài đặt chi tiết nằm trong `SETUP.md`.

---

## Thông tin dự án

| Khóa | Giá trị |
|---|---|
| Tên ứng dụng | `prm393_project` (trong `pubspec.yaml`) |
| Dart SDK | `^3.10.4` |
| Entrypoint chính | `lib/main.dart` |
| Cấu hình Firebase | `lib/firebase_options.dart` (tạo bởi FlutterFire) |
| Firebase Project ID | `prm393-project` |
| Vietnam Provinces API spec | `openapi.json` |

---

## Bắt đầu nhanh

Sử dụng `SETUP.md` làm nguồn tham khảo chính cho các điều kiện tiên quyết, thiết lập Firebase (SHA-1) và chạy trên thiết bị.

```bash
flutter pub get
flutter run
```

---

## Công nghệ sử dụng

| Lớp | Công nghệ |
|---|---|
| Frontend | Flutter (Dart 3) |
| Auth | Firebase Authentication — Email/Mật khẩu + Đăng nhập Google |
| Database | Cloud Firestore |
| Push notifications | Firebase Cloud Messaging (FCM) + flutter_local_notifications |
| Image hosting | Cloudinary (Upload qua HTTP, ký SHA-1) |
| Location data | Vietnam Provinces open API (`provinces.open-api.vn`) |
| Charts | fl_chart |
| Calendar UI | table_calendar |

> **Thanh toán**: Hỗ trợ Tiền mặt (COD) và Chuyển khoản ngân hàng trực tuyến qua PayOS.

---

## Cấu trúc thư mục

```
lib/
├── main.dart                    # Entry point; Khởi tạo Firebase + FCM
├── firebase_options.dart        # Tự động tạo bởi FlutterFire CLI
│
├── DTOs/                        # Lớp truyền dữ liệu (Kiểm tra + Chuyển đổi model)
│   ├── register_dto.dart
│   ├── create_booking_dto.dart
│   └── ...
│
├── models/                      # Các data model Firestore (fromMap / toMap)
│   ├── user_model.dart
│   ├── room_model.dart
│   ├── booking_model.dart
│   └── ...
│
├── services/                    # Lớp tương tác với Firebase/API
│   ├── auth_service.dart
│   ├── room_service.dart
│   ├── booking_service.dart
│   ├── withdrawal_service.dart  # Xử lý rút tiền & hoàn tiền
│   └── ...
│
├── screens/                     # Các màn hình UI phân theo role
│   ├── auth/                    # Login, Register...
│   ├── user/                    # Explore, RoomDetails, Bookings...
│   ├── host/                    # Dashboard, ManageRooms, Calendar...
│   └── admin/                   # Quản lý User, Duyệt phòng, Doanh thu...
│
├── widgets/                     # Các component UI dùng chung
│
└── utils/                       # Hàm tiện ích (Format tiền VND, ngày tháng...)
```

---

## Mô hình DTO (Data Transfer Object)

Tất cả các thao tác ghi dữ liệu đều đi qua DTO thay vì khởi tạo model trực tiếp. Mỗi DTO:
- Định nghĩa các trường cần thiết.
- Có hàm `validate()` để kiểm tra dữ liệu đầu vào.
- Có hàm `toModel()` để chuyển đổi sang Firestore model tương ứng.

---

## Mô hình dữ liệu (Firestore)

### Các collection chính

| Collection | Mô tả |
|---|---|
| `users/{uid}` | Thông tin cá nhân, phân quyền, FCM token, danh sách yêu thích |
| `rooms/{roomId}` | Danh sách phòng của Host |
| `rooms/{roomId}/daily_prices/{yyyy-MM-dd}` | Ghi đè giá theo ngày và chặn ngày |
| `bookings/{bookingId}` | Hồ sơ đặt phòng và máy trạng thái (Status machine) |
| `notifications/{notificationId}` | Hộp thư thông báo trong ứng dụng |
| `chat_rooms/{chatRoomId}` | Metadata phòng chat 1:1 |
| `withdrawal_requests/{requestId}` | Yêu cầu rút tiền (Host) hoặc hoàn tiền (User) |

---

## Chức năng theo vai trò (Role-based Capabilities)

### Người dùng (User)

**Khám phá & Tìm kiếm**
- Duyệt các phòng đang sẵn sàng (`available`).
- **Bộ lọc nâng cao**: Lọc theo bán kính khoảng cách (GPS) và khoảng giá mỗi giờ.
- Tìm kiếm theo tên phòng hoặc địa chỉ.
- Xem huy chương (Medal) của Host để đánh giá uy tín.

**Đặt phòng & Thanh toán**
- Quy trình đặt phòng: Chọn ngày giờ check-in/check-out riêng biệt.
- Tính giá theo giờ, tự động áp dụng giá ghi đè theo ngày (Daily Price).
- Áp dụng mã giảm giá (Voucher) hợp lệ.
- **Thanh toán trực tuyến qua PayOS**: Tự động tạo link thanh toán và mở trình duyệt.
- **Hủy phòng & Hoàn tiền**: Khi hủy một đơn đặt phòng đã thanh toán qua PayOS, hệ thống tự động yêu cầu thông tin ngân hàng để tạo yêu cầu hoàn tiền gửi đến Admin.

### Đối tác (Host)

- **Quản lý phòng**: Thêm, sửa, xóa phòng. Duyệt trạng thái phòng.
- **Quản lý lịch & giá**: Cài đặt giá đặc biệt cho từng ngày hoặc chặn các ngày không đón khách.
- **Rút doanh thu**: Dashboard theo dõi số dư khả dụng (chỉ tính từ các đơn PayOS đã hoàn thành). Gửi yêu cầu rút tiền về ngân hàng.
- **Hệ thống huy chương**: Tự động nhận huy chương (Đồng, Bạc, Vàng) dựa trên số lượng đơn hàng hoàn thành để tăng mức độ tin cậy.

### Quản trị viên (Admin)

- **Quản lý người dùng**: Khóa/mở khóa tài khoản, duyệt yêu cầu trở thành Host.
- **Duyệt phòng**: Kiểm duyệt các phòng mới do Host đăng tải.
- **Quản lý thanh toán**:
  - Duyệt các yêu cầu rút tiền của Host.
  - Duyệt các yêu cầu hoàn tiền của User khi hủy đơn PayOS.
  - Từ chối yêu cầu kèm lý do cụ thể (tự động thông báo cho người gửi).
- **Thống kê doanh thu**: Xem tổng quan doanh thu toàn sàn theo thời gian và trạng thái.

---

## Thông báo (Notifications)

- **Trigger**: Tự động gửi khi có đơn hàng mới, thay đổi trạng thái đơn, tin nhắn mới, hoặc yêu cầu rút tiền.
- **Kênh gửi**: 
  - Thông báo in-app (Lưu trong Firestore).
  - Push Notification (FCM) gửi trực tiếp đến thiết bị.
- **Đặc biệt**: Mọi yêu cầu tài chính (rút/hoàn tiền) đều được CC thông báo trực tiếp đến tài khoản quản trị hệ thống (`admin@system.com`).

---

## Cấu hình môi trường (`.env`)

Tạo file `.env` tại thư mục gốc với các thông tin sau:

```env
CLOUDINARY_CLOUD_NAME=your_name
CLOUDINARY_API_KEY=your_key
CLOUDINARY_API_SECRET=your_secret
API_URL=https://staybook-server.onrender.com (Dùng cho PayOS Webhook)
```

---

## Phát triển & Đóng góp

- Tất cả các lệnh ghi Firebase **phải** đi qua DTO.
- Đảm bảo `flutter analyze` không có lỗi trước khi commit.
- Cập nhật tài liệu này nếu có thay đổi về cấu trúc dữ liệu hoặc tính năng mới.

---

## Giấy phép (License)
Dự án được phát triển trong khuôn khổ môn học PRM393.
