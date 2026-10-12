# BÀI TẬP 2: ĐÓNG GÓI ỨNG DỤNG WEB BACKEND BẰNG SINGLE-STAGE DOCKERFILE

**Học phần:** Điện toán đám mây / DevOps (IT209)  
**Session:** 10 - Containerization with Docker  
**Thư mục bài làm:** `Lession10/Bai02`  
**GitHub Submission Path:** `homework/session_10/ex2/`

---

## 1. Mục tiêu bài thực hành
- Thiết kế và chuẩn hóa tệp `Dockerfile` mô hình Single-stage để đóng gói dịch vụ Web Backend REST API (Node.js/Express).
- Áp dụng các chỉ thị cốt lõi của Docker: `FROM`, `WORKDIR`, `ENV`, `COPY`, `RUN`, `EXPOSE`, `CMD` (ở định dạng exec form).
- Đóng gói ứng dụng thành Docker Image `hw-backend:v1` với kích thước tối ưu nhờ sử dụng base image `node:18-alpine`.
- Vận hành container `app-single-stage`, cấu hình ánh xạ cổng `8080:3000` và kiểm thử endpoint API.

---

## 2. Cấu trúc thư mục bài nộp

```text
Bai02/
├── .dockerignore        # Loại bỏ node_modules, logs và file không cần thiết khi build image
├── Dockerfile           # Tệp chỉ thị đóng gói ứng dụng Node.js (Single-stage)
├── package.json         # Khai báo metadata và thư viện phụ thuộc (express)
├── server.js            # Mã nguồn REST API Web Backend
└── README.md            # Báo cáo kỹ thuật và hướng dẫn kiểm thử
```

---

## 3. Mã nguồn ứng dụng Web Backend

### 3.1. File `package.json`
```json
{
  "name": "ex2-backend",
  "version": "1.0.0",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.2"
  }
}
```

### 3.2. File `server.js`
```javascript
const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.json({
    status: 'success',
    message: 'Hello from Docker Single-stage!'
  });
});

app.listen(PORT, () => {
  console.log(`Server listening on port ${PORT}`);
});
```

### 3.3. File `.dockerignore`
```text
node_modules
npm-debug.log
.git
.gitignore
README.md
```

---

## 4. Chi tiết Dockerfile Single-stage & Phân tích các chỉ thị

Tệp `Dockerfile` được thiết kế theo đúng quy chuẩn:

```dockerfile
# 1. Base Image tối giản dựa trên Alpine Linux cho Node.js 18
FROM node:18-alpine

# 2. Thiết lập thư mục làm việc bên trong container
WORKDIR /app

# 3. Khai báo biến môi trường PORT=3000
ENV PORT=3000

# 4. Sao chép định nghĩa phụ thuộc trước để tận dụng Docker Layer Cache
COPY package*.json ./

# 5. Cài đặt các dependencies cần thiết cho môi trường production
RUN npm install --omit=dev

# 6. Sao chép toàn bộ mã nguồn ứng dụng vào container
COPY . .

# 7. Khai báo cổng container lắng nghe
EXPOSE 3000

# 8. Lệnh khởi chạy ứng dụng ở dạng exec form (PID 1 nhận signal đúng cách)
CMD ["node", "server.js"]
```

### Phân tích kỹ thuật các chỉ thị:
1. **`FROM node:18-alpine`**: Sử dụng base image phiên bản Node.js 18 chạy trên nền Linux Alpine siêu nhẹ (~170MB so với ~1GB của bản Debian standard), giúp giảm dung lượng image và bề mặt tấn công bảo mật.
2. **`WORKDIR /app`**: Đặt thư mục làm việc mặc định cho tất cả các chỉ thị tiếp theo (`COPY`, `RUN`, `CMD`). Tránh ô nhiễm thư mục gốc (`/`).
3. **`ENV PORT=3000`**: Định nghĩa biến môi trường `PORT` để ứng dụng Node.js đọc qua `process.env.PORT`.
4. **`COPY package*.json ./` & `RUN npm install --omit=dev`**: Áp dụng kỹ thuật tối ưu **Docker Layer Caching**. Nếu mã nguồn `server.js` thay đổi nhưng dependencies không đổi, Docker sẽ tái sử dụng cache của layer này mà không phải tốn thời gian tải lại `node_modules`.
5. **`COPY . .`**: Sao chép toàn bộ mã nguồn vào thư mục `/app`. Kết hợp với `.dockerignore` để ngăn chặn việc copy đè thư mục `node_modules` ở máy host vào container.
6. **`EXPOSE 3000`**: Tài liệu hóa cổng mà container sẽ lắng nghe khi chạy.
7. **`CMD ["node", "server.js"]`**: Sử dụng cú pháp **Exec Form** (`["executable", "param1"]`) giúp tiến trình `node` chạy trực tiếp ở **PID 1**, đảm bảo tiếp nhận và xử lý chuẩn xác các tín hiệu dừng (`SIGTERM`, `SIGINT`) từ Docker engine (graceful shutdown).

---

## 5. Các bước triển khai và kiểm thử

### Bước 1: Build Docker Image
Thực thi lệnh đóng gói image với tag `hw-backend:v1`:
```bash
docker build -t hw-backend:v1 .
```

### Bước 2: Chạy Container từ Image
Khởi tạo và chạy container ở chế độ chạy nền (detached mode), đặt tên `app-single-stage` và ánh xạ cổng máy chủ `8080` vào cổng `3000` của container:
```bash
docker run -d --name app-single-stage -p 8080:3000 hw-backend:v1
```

### Bước 3: Kiểm tra trạng thái Container
```bash
docker ps
```
*Kết quả kỳ vọng:* Container `app-single-stage` có trạng thái `Up`, cổng `0.0.0.0:8080->3000/tcp`.

### Bước 4: Kiểm tra log của Container
```bash
docker logs app-single-stage
```
*Kết quả kỳ vọng:* Xuất hiện log `Server listening on port 3000`.

### Bước 5: Kiểm tra phản hồi API bằng `curl`
```bash
curl -i http://localhost:8080/
```
*Kết quả phản hồi thực tế từ hệ thống:*
```http
HTTP/1.1 200 OK
X-Powered-By: Express
Content-Type: application/json; charset=utf-8
Content-Length: 64
ETag: W/"40-upZb7Fps+hszzRU9BoKtiCsmGCQ"
Date: Mon, 12 Oct 2026 16:42:17 GMT
Connection: keep-alive
Keep-Alive: timeout=5

{"status":"success","message":"Hello from Docker Single-stage!"}
```

---

## 6. Dọn dẹp tài nguyên (Clean up)
Sau khi hoàn tất quá trình kiểm thử, có thể dừng và xóa container:
```bash
docker stop app-single-stage
docker rm app-single-stage
# Xóa image nếu không còn sử dụng:
docker rmi hw-backend:v1
```
