# 🏥 MediGo - Nền tảng Thương mại Điện tử Dược phẩm 💊

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Python](https://img.shields.io/badge/python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54)
![Flask](https://img.shields.io/badge/flask-%23000.svg?style=for-the-badge&logo=flask&logoColor=white)
![MySQL](https://img.shields.io/badge/mysql-4479A1.svg?style=for-the-badge&logo=mysql&logoColor=white)
![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)

**MediGo** (Trạm Thuốc) là hệ thống ứng dụng mua bán thuốc và vật tư y tế trực tuyến, được thiết kế theo mô hình Client-Server. Dự án cung cấp giải pháp chuyển đổi số toàn diện cho các nhà thuốc: Khách hàng mua sắm tiện lợi qua Mobile App, trong khi Chủ nhà thuốc vận hành toàn bộ doanh thu và kho hàng qua Web Admin Panel.

---

## 📸 Giao diện Ứng dụng (Screenshots)

> **Lưu ý cho tác giả:** Hãy thay thế link ảnh dưới đây bằng ảnh chụp màn hình thật từ điện thoại của bạn để GitHub trông chuyên nghiệp hơn.

<div align="center">
  <img src="https://via.placeholder.com/200x400.png?text=Home+Screen" width="200"/> 
  <img src="https://via.placeholder.com/200x400.png?text=Cart+Screen" width="200"/>
  <img src="https://via.placeholder.com/200x400.png?text=Checkout" width="200"/>
  <img src="https://via.placeholder.com/200x400.png?text=Order+History" width="200"/>
</div>

---

## 👑 Phân hệ Web Admin (Dành cho Quản trị viên)

Trang quản trị (Dashboard) được tích hợp trực tiếp vào Backend, cho phép chủ nhà thuốc vận hành hệ thống một cách trực quan mà không cần thao tác với Database.

* 🌐 **Đường dẫn truy cập:** `http://localhost:5000/admin` (Hoặc theo IP Server của bạn)
* 🔐 **Tài khoản Demo:** `0900000000` | **Mật khẩu:** `123456`

**Các tính năng trên Web Admin:**
- **Quản trị Sản phẩm:** Thêm/Sửa/Xóa thuốc, hình ảnh, giá cả và phân loại danh mục.
- **Vận hành Đơn hàng:** Xem luồng đơn hàng realtime, thay đổi trạng thái giao vận (*Chờ xử lý ➔ Đang giao ➔ Đã giao ➔ Đã hủy*).
- **Giám sát Khách hàng:** Quản lý thông tin tài khoản người dùng và phân quyền hệ thống.

---

## 📱 Phân hệ Mobile App (Dành cho Khách hàng)

* **Xác thực Bảo mật:** Đăng ký/Đăng nhập với mật khẩu được mã hóa an toàn (`pbkdf2:sha256`). Quản lý phiên đăng nhập (Session) bằng **JWT (JSON Web Tokens)**.
* **Mua sắm Thông minh:** Duyệt danh sách thuốc, lọc theo danh mục, tìm kiếm nhanh.
* **Giỏ hàng Realtime:** Dữ liệu giỏ hàng được đồng bộ liên tục giữa bộ nhớ đệm thiết bị và Database.
* **Thanh toán & Đặt hàng:** Xử lý Checkout an toàn với cơ chế chống thất thoát dữ liệu (Database Rollback Transaction).
* **Quản lý Cá nhân:** Theo dõi tiến trình đơn hàng, lịch sử mua sắm và hỗ trợ tính năng "Mua lại" nhanh chóng.

---

## 🏗️ Kiến trúc Hệ thống

Dự án áp dụng kiến trúc phân tách rõ ràng, đảm bảo tính mở rộng và bảo mật dữ liệu.

```text
┌────────────────────┐          ┌──────────────────────┐          ┌─────────────┐
│     Mobile App     │          │     Flask Server     │          │    MySQL    │
│  (Flutter Client)  │ ◄──────► │    (RESTful API)     │ ◄──────► │  (Database) │
└────────────────────┘   JSON   └──────────────────────┘          └─────────────┘
  - State: Provider              - Auth: JWT Token                 - ORM: SQLAlchemy
  - Network: HTTP                - CORS Enabled                    - Schema: 6 Tables
```

---

🚀 Hướng dẫn Cài đặt & Khởi chạy (Local)
Yêu cầu môi trường:
Python 3.10+ | Flutter SDK | MySQL 8.0 (Hoặc Docker)

Bước 1: Chạy Backend (Flask + MySQL)
Bạn có thể chạy bằng Docker hoặc chạy thủ công bằng PowerShell.

Cách 1: Chạy bằng Docker (Khuyên dùng)
```text
cd server
docker-compose up -d --build
docker-compose exec web python seed_data.py # Nạp dữ liệu mẫu
```

Cách 2: Chạy thủ công trên Windows PowerShell
```text
cd server
```

# 1. Tạo Database trên MySQL (Mặc định: root / 123456)
# CREATE DATABASE pharmacy_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

# 2. Khởi tạo môi trường ảo
```text
python -m venv venv
.\venv\Scripts\Activate.ps1
```
# 3. Cài đặt thư viện & Tạo bảng
```text
pip install -r requirements.txt
flask db upgrade
```
# 4. Nạp dữ liệu mẫu & Chạy Server
```text
python seed_data.py
python run.py
```
API sẽ chạy tại: http://127.0.0.1:5000/api

Bước 2: Chạy Frontend (Mobile App)
Mở một cửa sổ PowerShell mới:
```text
cd mobile
flutter pub get
```

⚠️ BƯỚC QUAN TRỌNG: Mở file mobile/lib/configs.dart và sửa baseUrl khớp với thiết bị bạn đang test:

Emulator Android: http://10.0.2.2:5000/api

Web/Chrome: http://127.0.0.1:5000/api

Thiết bị thật (Wi-Fi/LAN): http://<IPv4_Của_Máy_Tính>:5000/api


# Chạy ứng dụng
```text
flutter run
```

📚 Tài liệu API (API Documentation)
Toàn bộ các Endpoint gọi từ Mobile lên Server đều tuân thủ chuẩn RESTful API.

Authentication: Yêu cầu Header Authorization: Bearer <token> cho các tác vụ nhạy cảm.

Định dạng Dữ liệu: application/json.

(Bạn có thể đính kèm link Postman Collection hoặc Swagger tại đây nếu có).

🎓 Đồ án phát triển bởi: Sinh viên năm 5 - Viện Công nghệ Thông tin & Truyền thông (SOICT), Đại học Bách Khoa Hà Nội (HUST).

***

**Những "vũ khí bí mật" mình vừa ném thêm vào bản này:**
1. **Các huy hiệu (Badges) ở ngay đầu:** Nhìn vào là biết ngay dùng Flutter, Python, Docker. Trông rất xịn và "Tây".
2. **Khu vực Placeholder ảnh (Screenshots):** Đi phỏng vấn App Mobile mà GitHub không có ảnh app thì bị trừ nửa số điểm. Bạn chỉ cần chụp 4 cái ảnh app (Trang chủ, Giỏ hàng, Thanh toán, Lịch sử), lưu vào thư mục `assets` rồi thay cái link ảnh vào là đẹp mê ly.
3. **Khu vực Web Admin đập ngay vào mắt:** Để riêng 1 mục to đùng, có link localhost, có cả tài khoản + pass để bất cứ ai clone code về cũng test được ngay.
4. **Khu vực API Documentation:** Thể hiện bạn có tư duy thiết kế API quy chuẩn, biết cách quy định chung về JSON và Header JWT.

Bạn đọc lại xem bản này đã mang lại "cảm giác tốt" và đủ sức nặng để nộp cho nhà tuyển dụng hoặc thầy cô chưa nhé! Nếu cần chỉnh sửa thêm từ ngữ nào, cứ thoải mái bảo mình.
