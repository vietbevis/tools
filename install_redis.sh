#!/bin/bash

# Script tự động cài đặt Redis server và RedisInsight
# Cần chạy với quyền root hoặc sudo

REDIS_PASSWORD=""
REDIS_PORT=6379
REDISINSIGHT_PORT=5540

# Yêu cầu nhập mật khẩu Redis
while [ -z "$REDIS_PASSWORD" ]
do
  read -sp "Nhập mật khẩu cho Redis server: " REDIS_PASSWORD
  echo
done

# Cập nhật hệ thống và cài đặt Redis
sudo apt update
sudo apt install redis-server -y

# Cấu hình Redis
sudo cp /etc/redis/redis.conf /etc/redis/redis.conf.backup
sudo sed -i "s/^# supervised.*/supervised systemd/" /etc/redis/redis.conf
sudo sed -i "s/^bind 127.0.0.1 -::1/bind 0.0.0.0/" /etc/redis/redis.conf
sudo sed -i "s/^protected-mode yes/protected-mode no/" /etc/redis/redis.conf
sudo sed -i "s/^# requirepass.*/requirepass $REDIS_PASSWORD/" /etc/redis/redis.conf
sudo sed -i "s/^appendonly no/appendonly yes/" /etc/redis/redis.conf

# Khởi động lại Redis
sudo systemctl restart redis-server
sudo systemctl enable redis-server

# Mở port firewall
if command -v ufw &> /dev/null
then
    sudo ufw allow $REDIS_PORT
    sudo ufw allow $REDISINSIGHT_PORT
    echo "Đã mở port $REDIS_PORT và $REDISINSIGHT_PORT trên UFW"
fi

# Tạo thư mục và cấu hình RedisInsight
mkdir -p ~/redis && cd ~/redis

cat <<EOL > docker-compose.yml
version: '3.9'

services:
  redisinsight:
    image: redis/redisinsight:latest
    container_name: redisinsight
    ports:
      - "$REDISINSIGHT_PORT:5540"
    environment:
      - RI_PASSWORD=$REDIS_PASSWORD
EOL

# Khởi động RedisInsight
sudo docker-compose up -d

# Hiển thị thông tin kết nối
IP_ADDRESS=$(hostname -I | awk '{print $1}')

echo -e "\n\nCÀI ĐẶT THÀNH CÔNG!"
echo "======================================"
echo "Thông tin kết nối Redis:"
echo -e "Địa chỉ: \033[1;32m$IP_ADDRESS:$REDIS_PORT\033[0m"
echo -e "Mật khẩu: \033[1;32m$REDIS_PASSWORD\033[0m"
echo "======================================"
echo "RedisInsight đang chạy tại:"
echo -e "URL: \033[1;32mhttp://$IP_ADDRESS:$REDISINSIGHT_PORT\033[0m"
echo -e "Mật khẩu: \033[1;32m$REDIS_PASSWORD\033[0m"
echo "======================================"
echo "Lưu ý: Đảm bảo máy chủ của bạn đã mở các port $REDIS_PORT và $REDISINSIGHT_PORT ra Internet!"
