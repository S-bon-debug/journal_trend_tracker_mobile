# 📱 BẢNG PHÂN CÔNG NHIỆM VỤ FLUTTER MOBILE APP

> **Dự án:** Journal Trend Tracker (Mobile App)
> **Kiến trúc:** Feature-First (Phân tách theo tính năng sạch)
> **Trạng thái:**
> * `[ ]` Chưa bắt đầu (Not Started)
> * `[/]` Đang thực hiện (In Progress)
> * `[x]` Đã hoàn thành (Completed)

Mỗi thành viên làm chủ một module tính năng chính trên Flutter App và kết nối trực tiếp với API của thành viên Backend tương ứng. Hãy đánh dấu trạng thái nhiệm vụ của mình tại đây trước khi push code lên GitHub.

---

## 🧑💻 Thành viên 1 (M1): Base Project, Xác thực & Kết nối Gateway
*🎯 Bắt cặp trực tiếp với:* **P1 (IdentityService & API Gateway)**

### 🛠️ Nhiệm vụ Kỹ thuật & Cấu trúc nền tảng:
- [ ] Khởi tạo khung dự án Flutter chuẩn, thiết lập cấu trúc thư mục `core/` và `features/`.
- [ ] Thiết lập hệ thống định tuyến bằng `go_router`.
- [ ] Xây dựng hệ thống Theme (Light/Dark Mode, Color Palette, Fonts chữ từ `google_fonts`).
- [ ] Xây dựng layout điều hướng chính của App (**Shell Route** - chứa `BottomNavigationBar` để gắn kết các màn hình chính).
- [ ] Cấu hình **Dio HTTP Client** dùng chung cho toàn bộ app.
- [ ] Thiết lập **JWT Interceptor** tự động đính kèm `Bearer token` vào header, tự động gọi API `/refresh` làm mới token dưới nền khi hết hạn mà không ngắt quãng người dùng.

### 📱 Các màn hình cần tạo:
- [ ] **Màn hình khởi động (Splash):** `lib/features/auth/presentation/screens/splash_screen.dart`
  - *Mô tả:* Logo chào, kiểm tra trạng thái login cục bộ để chuyển hướng thông minh.
- [ ] **Màn hình Đăng nhập (Login):** `lib/features/auth/presentation/screens/login_screen.dart`
  - *Mô tả:* Đăng nhập Email + Mật khẩu & Đăng nhập nhanh bằng Google OAuth.
- [ ] **Màn hình Đăng ký (Register):** `lib/features/auth/presentation/screens/register_screen.dart`
  - *Mô tả:* Tạo tài khoản mới, chọn vai trò (`Student`, `Lecturer`, `Researcher`).

### 🔌 Tích hợp API Backend:
- `POST /api/identity/register`
- `POST /api/identity/login`
- `POST /api/identity/refresh`
- `POST /api/identity/logout`
- `GET /api/identity/auth/google/callback`

---

## 🧑💻 Thành viên 2 (M2): Bộ lọc Tìm kiếm & Xem chi tiết bài báo (Paper Discovery)
*🎯 Bắt cặp trực tiếp với:* **P2 (PaperService)**

### 🛠️ Nhiệm vụ Kỹ thuật:
- [ ] Xây dựng bộ lọc đa điều kiện động (Filter Drawer) gồm lọc theo từ khóa, năm, tác giả, tạp chí, nguồn API.
- [ ] Thiết lập gợi ý từ khóa thông minh (Search Autocomplete) khi người dùng nhập ký tự.
- [ ] Triển khai cơ chế **phân trang cuộn vô hạn (Infinite Scroll/Lazy Loading)** để tải danh sách bài viết mượt mà.

### 📱 Các màn hình cần tạo:
- [ ] **Màn hình Tìm kiếm chính (Search Home):** `lib/features/search/presentation/screens/search_home_screen.dart`
  - *Mô tả:* Thanh tìm kiếm autocomplete, danh sách bài báo dạng Card cuộn phân trang, nút mở bộ lọc nâng cao.
- [ ] **Màn hình Chi tiết bài báo (Paper Detail):** `lib/features/search/presentation/screens/paper_detail_screen.dart`
  - *Mô tả:* Hiển thị chi tiết tiêu đề, Abstract, tác giả, tạp chí, năm xuất bản, các tags từ khóa, nút chia sẻ và lưu bài viết.
- [ ] **Màn hình Danh sách Tác giả (Author Detail):** `lib/features/search/presentation/screens/author_detail_screen.dart`
  - *Mô tả:* Hiển thị thông tin tác giả và toàn bộ danh sách bài viết thuộc tác giả đó.
- [ ] **Màn hình Danh sách Tạp chí (Journal Detail):** `lib/features/search/presentation/screens/journal_detail_screen.dart`
  - *Mô tả:* Hiển thị thông tin tạp chí khoa học và danh mục bài viết thuộc tạp chí này.

### 🔌 Tích hợp API Backend:
- `GET /api/papers` (Tìm kiếm phân trang)
- `GET /api/papers/{id}` (Lấy chi tiết 1 bài báo)
- `GET /api/papers/keywords` (Autocomplete gợi ý từ khóa)
- `GET /api/papers/journals` (Lọc theo Tạp chí)
- `GET /api/papers/authors` (Lọc theo Tác giả)

---

## 🧑💻 Thành viên 3 (M3): Dashboard Xu hướng, Biểu đồ & Tải Báo cáo (Trend Hub)
*🎯 Bắt cặp trực tiếp với:* **P3 (TrendService)**

### 🛠️ Nhiệm vụ Kỹ thuật:
- [ ] Tích hợp thư viện đồ họa **`fl_chart`** để vẽ biểu đồ Line Chart biểu thị xu hướng tần suất bài báo qua từng năm.
- [ ] Thiết lập cơ chế lưu trữ file cục bộ (`path_provider`) để tải các báo cáo CSV/Excel về bộ nhớ thiết bị.
- [ ] Tích hợp công cụ mở file (`open_file`) giúp người dùng bấm vào xem trực tiếp hoặc chia sẻ file ra bên ngoài.

### 📱 Các màn hình cần tạo:
- [ ] **Màn hình Biểu đồ xu hướng (Trends Dashboard):** `lib/features/trends/presentation/screens/trends_dashboard_screen.dart`
  - *Mô tả:* Tổng quan thống kê nhanh, biểu đồ xu hướng trực quan tương tác được, và bảng hiển thị Top 10 Keywords, Authors, Journals, Hot Topics.
- [ ] **Màn hình Xuất báo cáo (Export Report):** `lib/features/trends/presentation/screens/export_report_screen.dart`
  - *Mô tả:* Giao diện tùy chọn tham số xuất báo cáo (chọn từ khóa, chọn định dạng CSV/Excel), nút bắt đầu tải xuống và quản lý lịch sử các file báo cáo đã tải về.

### 🔌 Tích hợp API Backend:
- `GET /api/trends/overview` (Xem số liệu tổng quan hệ thống)
- `GET /api/trends/keywords/{keywordId}` & `/api/trends/journals/{journalId}` (Lấy số liệu vẽ biểu đồ xu hướng)
- `GET /api/trends/top-keywords` & `top-authors` & `top-journals` (Lấy danh sách bảng xếp hạng Top 10)
- `GET /api/trends/hot-topics` (Danh sách chủ đề đang nóng)
- `GET /api/trends/reports/export` (Tải xuống file báo cáo xu hướng)

---

## 🧑💻 Thành viên 4 (M4): Trang cá nhân, Tương tác (Bookmark/Follow) & Thông báo
*🎯 Bắt cặp trực tiếp với:* **P4 (UserService)**

### 🛠️ Nhiệm vụ Kỹ thuật:
- [ ] Quản lý đồng bộ trạng thái tương tác Bookmark (Lưu bài viết) và Follow (Theo dõi từ khóa/tạp chí) trên toàn app.
- [ ] Thiết lập hệ thống **Thông báo cục bộ (Local Notifications)** nhận thông báo đẩy tin tức bài báo mới.
- [ ] Thiết kế form cập nhật thông tin profile bảo mật.

### 📱 Các màn hình cần tạo:
- [ ] **Màn hình Trang cá nhân (User Profile):** `lib/features/profile/presentation/screens/profile_screen.dart`
  - *Mô tả:* Hiển thị/chỉnh sửa Bio, Đơn vị công tác, Lĩnh vực nghiên cứu ưu tiên.
- [ ] **Màn hình Quản lý Lưu trữ (Bookmarks & Follows):** `lib/features/profile/presentation/screens/bookmarks_screen.dart`
  - *Mô tả:* Danh sách bài viết đã lưu (Bookmarks) và danh sách từ khóa/tạp chí đang theo dõi (Follows).
- [ ] **Màn hình Thông báo (Notifications Center):** `lib/features/notifications/presentation/screens/notifications_screen.dart`
  - *Mô tả:* Danh sách thông báo đẩy bài viết mới, lọc trạng thái chưa đọc, nút đánh dấu đã đọc toàn bộ.

### 🔌 Tích hợp API Backend:
- `GET /api/users/profile` & `PUT /api/users/profile` (Đọc/Cập nhật thông tin Profile)
- `GET /api/users/bookmarks` & `POST /api/users/bookmarks` & `DELETE /api/users/bookmarks/{id}` (Quản lý bài báo đã lưu)
- `GET /api/users/follows` & `POST /api/users/follows/...` & `DELETE /api/users/follows/{id}` (Theo dõi từ khóa/tạp chí)
- `GET /api/users/notifications` & `PUT /api/users/notifications/{id}/read` & `PUT /api/users/notifications/read-all` (Xử lý thông báo)

---

## 🧑💻 Thành viên 5 (M5): Cài đặt App, Màn hình Quản trị Admin & DevOps Mobile
*🎯 Bắt cặp trực tiếp với:* **P5 (AdminService)**

### 🛠️ Nhiệm vụ Kỹ thuật:
- [ ] Triển khai phân quyền giao diện (Role-Based Control): Chỉ hiện nút quản trị Admin khi Role = `admin`.
- [ ] Quản lý lưu cài đặt ứng dụng cục bộ (`shared_preferences`) gồm chế độ Sáng/Tối (Dark Mode) và Ngôn ngữ.
- [ ] **DevOps Mobile:** Cấu hình build môi trường khác nhau (`flavors` cho Dev và Production), cài đặt tự động hóa CI/CD build file APK/AAB cho dự án, viết tài liệu cài đặt của ứng dụng.

### 📱 Các màn hình cần tạo:
- [ ] **Màn hình Cài đặt chung (App Settings):** `lib/features/settings/presentation/screens/settings_screen.dart`
  - *Mô tả:* Đổi Theme Sáng/Tối, Đổi Ngôn ngữ, Đăng xuất, Nút đi đến Admin Panel (Chỉ hiển thị cho tài khoản Admin).
- [ ] **Bảng điều khiển Admin (Admin Dashboard):** `lib/features/admin/presentation/screens/admin_dashboard_screen.dart`
  - *Mô tả:* Dashboard tổng hợp số liệu quản trị, danh mục quản trị chính.
- [ ] **Quản lý Thành viên (User Management):** `lib/features/admin/presentation/screens/user_management_screen.dart`
  - *Mô tả:* Danh sách toàn bộ thành viên hệ thống kèm nút **Khóa / Mở khóa** tài khoản.
- [ ] **Quản lý Đồng bộ (API Sync Manager):** `lib/features/admin/presentation/screens/sync_manager_screen.dart`
  - *Mô tả:* Bật/Tắt nguồn API ngoài (OpenAlex, Semantic Scholar) và bảng log theo dõi chi tiết lịch sử đồng bộ dữ liệu.

### 🔌 Tích hợp API Backend:
- `GET /api/admin/users` & `PUT /api/admin/users/{id}/toggle` (Quản lý User)
- `GET /api/admin/api-sources` & `PUT /api/admin/api-sources/{id}/toggle` (Bật/tắt nguồn API)
- `GET /api/admin/sync-jobs` (Đọc danh sách lịch sử sync dữ liệu)
- `GET /api/admin/settings` & `PUT /api/admin/settings` (Cập nhật cài đặt hệ thống)
