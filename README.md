# CDC Pipeline: MySQL → Kafka → Spark → MongoDB

> **Đồ án tốt nghiệp** - Change Data Capture pipeline đồng bộ dữ liệu gần real-time

**Tác giả**: Cao Xuân Phô  
**Trạng thái**: 🟡 POC Phase - Demo từng công cụ một

---

## 📊 Progress Tracker

| Phase | Component | Status | Ngày hoàn thành |
|-------|-----------|--------|-----------------|
| 1 | MySQL 8.0 + Binary Log | ✅ Hoàn thành | 2026-02-24 |
| 2 | MongoDB 7.0 | 🟡 Đang làm | TBD |
| 3 | Kafka + Zookeeper | ⏳ Sắp tới | - |
| 4 | Debezium (MySQL→Kafka) | ⏳ Sắp tới | - |
| 5 | Spark Streaming (Kafka→MongoDB) | ⏳ Sắp tới | - |
| 6 | Full Pipeline Integration | ⏳ Sắp tới | - |
| 7 | Testing & Documentation | ⏳ Sắp tới | - |

---

## 🛠️ Tech Stack

```
MySQL 8.0         → Source database (port 3306)
Debezium 2.5      → CDC connector (port 8083) 
Kafka 7.5.0       → Message broker (port 9092)
Spark 3.5.0       → Stream processing (port 8888)
MongoDB 7.0       → Target database (port 27017)
Docker 29.x       → Containerization
```

---

## 💻 Hệ thống yêu cầu

- **OS**: Linux (Linux Mint 22+, Ubuntu, ...)
- **RAM**: 32GB
- **Disk**: 50GB+ free space
- **Docker**: v29.1.3+
- **Docker Compose**: v5.0.0+

---

## 📋 Quick Start

### Bước 1: Clone repo
```bash
git clone https://github.com/JohnWickCP/cdc-pipeline-mysql-kafka-spark-mongodb.git
cd cdc-pipeline-mysql-kafka-spark-mongodb
```

### Bước 2: Cấu trúc thư mục
```bash
mkdir -p {mysql,mongodb,kafka,spark,debezium,pipeline,screenshots}
```

---

## 🚀 Phase 1: MySQL (✅ Hoàn thành)

### Trạng thái
- ✅ Docker MySQL image đã pull
- ✅ Container chạy (cdc-mysql)
- ✅ Binary Log bật (`--binlog-format=ROW`)
- ✅ Sample data đã insert
- ✅ Test connection thành công

### Docker Compose
```yaml
# mysql/docker-compose.yml
version: '3.8'
services:
  mysql:
    image: mysql:8.0
    container_name: cdc-mysql
    environment:
      MYSQL_ROOT_PASSWORD: root123
      MYSQL_DATABASE: testdb
      MYSQL_USER: cdc_user
      MYSQL_PASSWORD: cdc123
    ports:
      - "3306:3306"
    command:
      - --server-id=1
      - --log-bin=mysql-bin
      - --binlog-format=ROW
      - --binlog-row-image=FULL
```

### Test MySQL
```bash
docker exec -it cdc-mysql mysql -u root -proot123 testdb
> SHOW MASTER STATUS;           # Kiểm tra binlog
> SELECT * FROM orders;         # Xem sample data
```

---

## 🚀 Phase 2: MongoDB (🟡 Đang làm)

### Mục tiêu
- [x] Docker MongoDB image đã pull
- [x] Container chạy (cdc-mongodb)
- [ ] Test kết nối thành công
- [ ] Sample collections tạo thành công
- [ ] Screenshots chụp & commit

### Docker Compose
File: `mongodb/docker-compose.yml`
```yaml
version: '3.8'

services:
  mongodb:
    image: mongo:7.0
    container_name: cdc-mongodb
    environment:
      MONGO_INITDB_ROOT_USERNAME: root
      MONGO_INITDB_ROOT_PASSWORD: root123
      MONGO_INITDB_DATABASE: testdb
    ports:
      - "27017:27017"
    volumes:
      - mongodb_data:/data/db
    restart: unless-stopped
    healthcheck:
      test: echo 'db.adminCommand("ping")' | mongosh --quiet
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  mongodb_data:
    driver: local
```

### Bước cài đặt & Test

#### Step 1: Cập nhật docker-compose (nếu cần)
```bash
cd ~/cdc-pipeline/mongodb

# Cập nhật file với volume & healthcheck
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  mongodb:
    image: mongo:7.0
    container_name: cdc-mongodb
    environment:
      MONGO_INITDB_ROOT_USERNAME: root
      MONGO_INITDB_ROOT_PASSWORD: root123
      MONGO_INITDB_DATABASE: testdb
    ports:
      - "27017:27017"
    volumes:
      - mongodb_data:/data/db
    restart: unless-stopped
    healthcheck:
      test: echo 'db.adminCommand("ping")' | mongosh --quiet
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  mongodb_data:
    driver: local
EOF

# Restart container
docker compose down
docker compose up -d
```

#### Step 2: Kiểm tra containers chạy
```bash
docker ps
```
**Expected output**: Cả cdc-mysql và cdc-mongodb running

**📸 Screenshot name**: `02-mongodb-running.png`
- Chụp output của `docker ps` show cả MySQL & MongoDB

#### Step 3: Test ping MongoDB
```bash
docker exec -it cdc-mongodb mongosh -u root -p root123 --authenticationDatabase admin testdb --eval "db.adminCommand('ping')"
```
**Expected output**: `{ ok: 1 }`

#### Step 4: Tạo collection & insert data mẫu
```bash
docker exec -it cdc-mongodb mongosh -u root -p root123 --authenticationDatabase admin testdb << 'EOF'
// Tạo collection
db.createCollection('orders')

// Insert sample data
db.orders.insertMany([
  {
    id: 1,
    product: "Laptop",
    quantity: 2,
    price: 1200.00,
    status: "completed",
    created_at: new Date()
  },
  {
    id: 2,
    product: "Mouse",
    quantity: 5,
    price: 25.00,
    status: "pending",
    created_at: new Date()
  },
  {
    id: 3,
    product: "Keyboard",
    quantity: 3,
    price: 75.00,
    status: "completed",
    created_at: new Date()
  }
])

// Hiển thị dữ liệu
print("\n=== Data in orders collection ===")
db.orders.find().pretty()
EOF
```

#### Step 5: Verify dữ liệu
```bash
docker exec -it cdc-mongodb mongosh -u root -p root123 --authenticationDatabase admin testdb --eval "db.orders.find().pretty()"
```

**📸 Screenshot name**: `03-mongodb-sample-data.png`
- Chụp output của lệnh trên, hiển thị 3 records

### Kết quả mong đợi
```javascript
{
  _id: ObjectId('65d4a1f2b8c9d0e1f2g3h4i5'),
  id: 1,
  product: 'Laptop',
  quantity: 2,
  price: 1200,
  status: 'completed',
  created_at: ISODate('2026-02-24T...')
},
{
  _id: ObjectId('65d4a1f2b8c9d0e1f2g3h4i6'),
  id: 2,
  product: 'Mouse',
  quantity: 5,
  price: 25,
  status: 'pending',
  created_at: ISODate('2026-02-24T...')
},
{
  _id: ObjectId('65d4a1f2b8c9d0e1f2g3h4i7'),
  id: 3,
  product: 'Keyboard',
  quantity: 3,
  price: 75,
  status: 'completed',
  created_at: ISODate('2026-02-24T...')
}
```

### Commit GitHub
```bash
cd ~/cdc-pipeline

# Add files
git add mongodb/docker-compose.yml
git add screenshots/02-mongodb-running.png
git add screenshots/03-mongodb-sample-data.png

# Commit
git commit -m "feat(mongodb): add docker-compose with sample data

- MongoDB 7.0 with root credentials
- Volume for data persistence
- Healthcheck configured
- Sample collection 'orders' with 3 test records
- Screenshots: containers running, sample data"

# Push
git push origin main

# Verify
git log --oneline -2
```

---

## 🚀 Phase 3: Kafka + Zookeeper (⏳ Sắp tới)

**Status**: ⏳ Chờ Phase 2 (MongoDB) hoàn thành ✅

### Mục tiêu
- [ ] Zookeeper + Kafka container chạy
- [ ] Test topic creation
- [ ] Test message producer/consumer
- [ ] Screenshots chụp & commit

### Docker Compose
File: `kafka/docker-compose.yml`

```yaml
version: '3.8'

services:
  zookeeper:
    image: confluentinc/cp-zookeeper:7.5.0
    container_name: cdc-zookeeper
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000
    ports:
      - "2181:2181"
    restart: unless-stopped
    healthcheck:
      test: echo srvr | nc -w 2 localhost 2181 || exit 1
      interval: 10s
      timeout: 5s
      retries: 5

  kafka:
    image: confluentinc/cp-kafka:7.5.0
    container_name: cdc-kafka
    depends_on:
      zookeeper:
        condition: service_healthy
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:29092,PLAINTEXT_HOST://kafka:9092
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT
      KAFKA_INTER_BROKER_LISTENER_NAME: PLAINTEXT
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_AUTO_CREATE_TOPICS_ENABLE: "true"
      KAFKA_LOG_RETENTION_HOURS: 24
    ports:
      - "9092:9092"
      - "29092:29092"
    restart: unless-stopped
    healthcheck:
      test: kafka-broker-api-versions.sh --bootstrap-server localhost:9092 | head -10
      interval: 10s
      timeout: 5s
      retries: 5

  kafka-ui:
    image: provectuslabs/kafka-ui:latest
    container_name: cdc-kafka-ui
    depends_on:
      kafka:
        condition: service_healthy
    environment:
      KAFKA_CLUSTERS_0_NAME: cdc-cluster
      KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS: kafka:29092
      KAFKA_CLUSTERS_0_ZOOKEEPER: zookeeper:2181
    ports:
      - "8080:8080"
    restart: unless-stopped
```

### Bước cài đặt & Test

#### Step 1: Tạo kafka/docker-compose.yml
```bash
cd ~/cdc-pipeline

mkdir -p kafka

cat > kafka/docker-compose.yml << 'EOF'
[paste the YAML above]
EOF
```

#### Step 2: Khởi động Kafka & Zookeeper
```bash
cd kafka
docker compose up -d

# Chờ ~20s để services khởi động
sleep 20

# Kiểm tra
docker ps | grep -E "cdc-kafka|cdc-zookeeper"
```

**📸 Screenshot name**: `04-kafka-running.png`
- Chụp output của `docker ps` show cdc-mysql, cdc-mongodb, cdc-kafka, cdc-zookeeper

#### Step 3: Test tạo topic
```bash
docker exec cdc-kafka kafka-topics.sh --create \
  --bootstrap-server kafka:9092 \
  --topic test-topic \
  --partitions 1 \
  --replication-factor 1
```

**Expected output**: `Created topic test-topic.`

#### Step 4: List topics
```bash
docker exec cdc-kafka kafka-topics.sh --list --bootstrap-server kafka:9092
```

**Expected output**: `test-topic`

#### Step 5: Test producer (gửi message)
```bash
docker exec -it cdc-kafka bash -c \
  'echo -e "Hello Kafka\nMessage 2\nMessage 3" | kafka-console-producer.sh --broker-list kafka:9092 --topic test-topic'
```

**Expected output**: Không có output (tức là messages đã được gửi)

#### Step 6: Test consumer (nhận message)
```bash
docker exec -it cdc-kafka kafka-console-consumer.sh \
  --bootstrap-server kafka:9092 \
  --topic test-topic \
  --from-beginning
```

**Expected output**:
```
Hello Kafka
Message 2
Message 3
```

Nhấn `Ctrl+C` để thoát.

**📸 Screenshot name**: `05-kafka-producer-consumer.png`
- Chụp output của producer + consumer test

#### Step 7: Kafka UI (Web Interface - Optional)
```
🔗 URL: http://localhost:8080
```

Navigate to "Topics" để xem test-topic

**📸 Screenshot name**: `06-kafka-ui.png` (optional)
- Chụp Kafka UI homepage

### Commit GitHub
```bash
cd ~/cdc-pipeline

# Add files
git add kafka/docker-compose.yml
git add screenshots/04-kafka-running.png
git add screenshots/05-kafka-producer-consumer.png
git add screenshots/06-kafka-ui.png  # (nếu chụp)

# Commit
git commit -m "feat(kafka): add zookeeper and kafka broker configuration

- Zookeeper 7.5.0 for coordination
- Kafka 7.5.0 broker with plaintext protocol
- Kafka UI 8080 for monitoring
- Auto topic creation enabled
- Healthchecks configured
- Screenshots: containers running, producer/consumer test, Kafka UI"

# Push
git push origin main
```

## 🚀 Phase 4: Debezium (⏳ Sắp tới)

**Mục tiêu**: Kết nối MySQL Binary Log → Kafka topics

**Dự kiến**: Sau Kafka ✅

---

## 🚀 Phase 5: Spark Streaming (⏳ Sắp tới)

**Mục tiêu**: Consume từ Kafka → Xử lý → Ghi MongoDB

**Dự kiến**: Sau Debezium ✅

---

## 📁 Cấu trúc Project

```
cdc-pipeline-mysql-kafka-spark-mongodb/
├── mysql/
│   └── docker-compose.yml          # ✅ Hoàn thành
├── mongodb/
│   └── docker-compose.yml          # 🟡 Đang làm
├── kafka/
│   └── docker-compose.yml          # ⏳ Sắp tới
├── spark/
│   └── docker-compose.yml          # ⏳ Sắp tới
├── debezium/
│   └── docker-compose.yml          # ⏳ Sắp tới
├── pipeline/
│   └── docker-compose.yml          # ⏳ Sắp tới (full tích hợp)
├── screenshots/                     # Chứng minh từng bước
│   ├── 01-mysql-running.png        # ✅
│   └── 02-mongodb-running.png      # 🟡
├── README.md                        # File này
└── .gitignore
```

---

## 📸 Screenshots

| Phase | Screenshot | Mô tả |
|-------|-----------|-------|
| 1 | `01-mysql-running.png` | MySQL container chạy + test data |
| 2 | `02-mongodb-running.png` | MongoDB container chạy + test insert |
| 3 | `03-kafka-running.png` | Kafka + Zookeeper chạy + test topic |
| 4 | `04-debezium-connector.png` | Debezium connector registered |
| 5 | `05-spark-streaming.png` | Spark jobs consuming Kafka |
| 6 | `06-full-pipeline.png` | Data flow MySQL → MongoDB |

---

## 🔧 Lệnh hữu ích

```bash
# Kiểm tra tất cả containers
docker ps -a

# View logs
docker logs <container_name> -f

# Connect vào container
docker exec -it <container_name> bash

# Remove all containers
docker compose down
docker volume prune

# Rebuild images
docker compose up -d --build

# Git status
git status

# Commit changes
git add .
git commit -m "feat: description"
git push origin main
```

---

## 📝 Commit Convention

**Format**: `<type>(<scope>): <subject>`

Examples:
```
feat(mysql): add docker-compose with binlog enabled
feat(mongodb): add docker-compose with healthcheck
fix(kafka): update bootstrap server configuration
docs(readme): add phase 3 instructions
test(debezium): verify connector status endpoint
```

---

## ✅ Checklist - Phase 2 (MongoDB)

- [ ] Docker Compose file tạo
- [ ] Container start thành công
- [ ] Test ping MongoDB → OK
- [ ] Tạo collection 'orders' → OK
- [ ] Insert sample data → OK
- [ ] Screenshot chụp → lưu vào `screenshots/02-mongodb-running.png`
- [ ] Commit lên GitHub → `git push`
- [ ] Update README.md → Mark Phase 2 complete ✅

---

## 📚 References

- [Docker Documentation](https://docs.docker.com/)
- [MongoDB Documentation](https://docs.mongodb.com/)
- [Apache Kafka Documentation](https://kafka.apache.org/documentation/)
- [Debezium Documentation](https://debezium.io/documentation/)
- [Apache Spark Documentation](https://spark.apache.org/docs/)

---

## 🤝 Contributors

- Cao Xuân Phô (Author)

---

**Last Updated**: 2026-02-24  
**Next Phase**: Kafka + Zookeeper (Phase 3)