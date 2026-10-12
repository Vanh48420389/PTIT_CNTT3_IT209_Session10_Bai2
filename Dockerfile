# Base Image tối giản dựa trên Alpine Linux cho Node.js 18
FROM node:18-alpine

# Thiết lập thư mục làm việc bên trong container
WORKDIR /app

# Khai báo biến môi trường PORT=3000
ENV PORT=3000

# Copy các file mô tả dependencies trước để tận dụng triệt để Docker Layer Caching
COPY package*.json ./

# Cài đặt các dependencies cần thiết cho môi trường production
RUN npm install --omit=dev

# Sao chép toàn bộ mã nguồn ứng dụng vào container
COPY . .

# Khai báo cổng container lắng nghe
EXPOSE 3000

# Lệnh khởi chạy ứng dụng ở dạng exec form
CMD ["node", "server.js"]
