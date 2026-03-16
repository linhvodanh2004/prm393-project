## Quy trình kiểm thử dự án

Tài liệu này mô tả **workflow kiểm thử** cho ứng dụng đặt phòng (Flutter + Firebase), dùng cho cả dev và QA. Ngôn ngữ: **Tiếng Việt**.

---

## 1. Mục tiêu

- Đảm bảo các luồng chính (User / Host / Admin) luôn chạy đúng sau mỗi thay đổi.
- Giảm lỗi sản xuất bằng kiểm thử tự động (unit/widget test) kết hợp kiểm thử thủ công có kịch bản rõ ràng.
- Chuẩn hóa quy trình kiểm thử trước khi merge pull request và trước khi phát hành (release).

---

## 2. Điều kiện tiên quyết

- Đã cấu hình dự án theo `SETUP.md` (Firebase, Google Sign-In, FCM…).
- Có ít nhất:
  - 01 tài khoản **USER**
  - 01 tài khoản **HOST** (được duyệt qua flow *Become Host*)
  - 01 tài khoản **ADMIN**
- Thiết bị kiểm thử:
  - 1 máy thật Android (ưu tiên có Google Play Services) để test FCM.
  - 1 emulator Android/iOS để test giao diện đa kích thước.

---

## 3. Các loại kiểm thử

- **Unit test**: Kiểm thử logic thuần (service, validator, mapper).
- **Widget test**: Kiểm thử UI nhỏ (form, component quan trọng).
- **Integration / Manual test**: Chạy app thật, kiểm thử end-to-end các luồng chính.

Chạy test tự động:

```bash
flutter test
```

---

## 4. Workflow kiểm thử khi phát triển (per feature / per PR)

1. **Viết / cập nhật unit test (nếu có)**
   - BookingService (trạng thái, double-booking).
   - VoucherService (scope HOST/GLOBAL, minSubtotal, usage limit).
   - Validator (email, CCCD, số điện thoại…).

2. **Chạy `flutter test`**
   - PR **không được merge** nếu test đang fail.

3. **Kiểm thử thủ công nhanh trên simulator/emulator**
   - Đăng nhập bằng **USER**, kiểm tra:
     - Khám phá phòng (ExploreScreen): lọc, tìm kiếm.
     - Xem chi tiết phòng: ảnh, mô tả, tiện ích, giá theo ngày.
     - Tạo 1 booking mới (không voucher và có voucher).
   - Đăng nhập bằng **HOST**, kiểm tra:
     - Nhận booking, **confirm / reject / completed**.
   - Đăng nhập bằng **ADMIN**, kiểm tra:
     - Màn hình quản trị chính liên quan đến feature vừa sửa (nếu có).

4. **Kiểm tra log lỗi**
   - Không để lại `print(e)` cho các luồng quan trọng; thay bằng xử lý lỗi rõ ràng + SnackBar/Alert.

---

## 5. Workflow kiểm thử trước khi release

### 5.1. Kiểm thử chức năng theo vai trò

#### User

- **Đăng ký / Đăng nhập**
  - Đăng ký tài khoản mới (email hợp lệ, mật khẩu >= 6 ký tự).
  - Đăng nhập, đăng xuất, quên mật khẩu.
- **Hồ sơ**
  - Cập nhật họ tên, số điện thoại (10 số, bắt đầu bằng 0), địa chỉ, ngày sinh.
- **Khám phá & yêu thích**
  - Tìm phòng theo tên, lọc theo tiện ích, giá.
  - Thêm/bỏ **Yêu thích** (FavoritesScreen hiển thị đúng).
- **Đặt phòng**
  - Chọn ngày check-in/check-out, số khách.
  - Giá tổng = tổng giá từng ngày (kiểm tra ngày có daily_price và không có).
  - Tạo booking **không dùng voucher**.
  - Tạo booking **dùng voucher HOST** (phòng thuộc host A).
  - Tạo booking **dùng voucher GLOBAL**.
- **Quản lý booking**
  - Tab “Chờ duyệt”: có nút **Hủy** cho booking `pending`.
  - Tab “Sắp tới”, “Lịch sử” hiển thị trạng thái đúng.
  - Mở chat với Host từ booking.

#### Host

- **Become Host**
  - Gửi yêu cầu với CCCD/CMND hợp lệ (9 hoặc 12 số).
  - Khi status `pending` thì form bị khóa, chỉ hiển thị trạng thái.
- **Quản lý phòng**
  - Tạo phòng mới, chỉnh sửa phòng, cập nhật hình ảnh/giá.
  - Thử xóa phòng:
    - Nếu có booking `pending/confirmed/paid` → phải bị chặn.
    - Nếu không có booking active → xóa thành công.
- **Booking**
  - Tab chờ duyệt: có confirm + reject (kèm dialog).
  - Khi confirm:
    - Nếu đã có booking khác trùng ngày (`confirmed/paid`) → phải báo lỗi, không cho xác nhận.
  - Với booking `paid`: có nút **Đánh dấu hoàn thành**.
- **Lịch (Calendar)**
  - Chọn phòng, chặn ngày, chỉnh giá từng ngày; reload lại vẫn đúng.
- **Voucher (Host)**
  - Tạo voucher scope=HOST, minSubtotal, type PERCENT/FIXED.
  - Tắt/bật voucher; test dùng ở RoomDetailsScreen của chính host.

#### Admin

- **Manage Users**
  - Tìm kiếm theo tên/email.
  - Khóa/mở khóa tài khoản (isActive).
  - Nâng USER → HOST, hạ HOST → USER.
- **Host Requests**
  - Tab yêu cầu: approve (user thành HOST), reject (lưu lý do).
- **Rooms**
  - Tab chờ duyệt: duyệt / từ chối phòng (status: `available` / `unavailable`).
- **Bookings**
  - Xem toàn bộ bookings, lọc theo trạng thái.
  - Thực hiện **force cancel** và **force complete** cho 1 số booking test.
- **Payments**
  - Tab Doanh thu: tổng tiền, số giao dịch khớp với booking `paid/completed`.
  - Tab Hoàn tiền: hiển thị các booking `cancelled` có tổng tiền > 0.
- **Voucher (Global)**
  - Tạo voucher scope=GLOBAL, kiểm tra áp dụng được cho mọi phòng.

### 5.2. Kiểm thử chat (chỉ 1-1)

- Đảm bảo:
  - `chat_rooms.participants.length == 2`.
  - RoomId dạng `<min(uidA,uidB)>_<max(uidA,uidB)>`, không tạo trùng.
- Luồng kiểm thử:
  - USER nhắn HOST từ booking → tạo/mở phòng chat.
  - HOST trả lời -> USER nhận noti, badge.
  - Mở màn hình ChatDetail: kiểm tra unread về 0.

### 5.3. Kiểm thử thông báo (in-app + thiết bị)

- **Thiết lập**: đăng nhập trên máy thật, đảm bảo `users/{uid}.fcmToken` được lưu.
- **Case cần test:**
  - Tạo booking mới → Host nhận in-app + push.
  - Host đổi trạng thái booking (confirm/reject/paid/completed/cancel) → User nhận in-app + push.
  - Gửi tin nhắn chat → bên kia nhận in-app + push (khi app background).
  - Gửi yêu cầu Become Host → Admin nhận noti.
  - Admin duyệt/từ chối → User nhận noti.
- Mở notification từ hệ thống → app điều hướng đến:
  - Booking: UserBookingsScreen/HostBookingsScreen.
  - Chat: ChatDetailScreen (đúng roomId).
  - Host request: BecomeHostScreen hoặc ManageUsersScreen (Admin).

---

## 6. Checklist nhanh trước khi merge / release

- **Tự động**
  - [ ] `flutter test` chạy **pass**.
- **Thủ công (tối thiểu)**
  - [ ] Đăng nhập USER + đặt 1 booking mới.
  - [ ] Đăng nhập HOST + confirm 1 booking, kiểm tra noti.
  - [ ] Đăng nhập USER + hủy 1 booking `pending`.
  - [ ] Kiểm tra 1 chat USER ↔ HOST hoạt động + unread badge.
  - [ ] Thử 1 voucher HOST + 1 voucher GLOBAL.
  - [ ] Admin xem được bookings + doanh thu.
  - [ ] Không thấy lỗi crash/lỗi nghiêm trọng trong log trên thiết bị thật.

