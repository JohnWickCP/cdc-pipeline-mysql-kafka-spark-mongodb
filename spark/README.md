# Spark Structured Streaming – CDC Consumer

Module này tiêu thụ các sự kiện CDC từ Debezium trên Kafka và xử lý chúng bằng Apache Spark Structured Streaming.

## Vị Trí Kiến Trúc

```
MySQL → Debezium → Kafka → Spark (module này) → Sink (Console / MongoDB / Redis)
```

## Yêu Cầu Tiên Quyết

- Docker và Docker Compose được cài đặt
- Các dịch vụ Docker chạy với `docker-compose.yml`
- Spark 3.5.0
- Kafka client phiên bản 3.4.1

## Bắt Đầu

### 1. Khởi Động Spark Cluster

Đảm bảo các dịch vụ Docker đang chạy:

```bash
docker compose -f pipeline/docker-compose.yml up -d
```

Kiểm tra tất cả các container đang chạy:

```bash
docker ps
```

Truy cập Giao diện Spark Master tại: http://localhost:8080

### 2. Vào Vào Container Spark Master

```bash
docker exec -it cdc-spark-master bash
```

### 3. Khởi Động Spark Shell với Package Kafka

Chạy Spark Shell với các phụ thuộc Kafka cần thiết:

```bash
/opt/spark/bin/spark-shell \
  --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.5.0
```

**Lưu ý:** Khi paste code vào spark-shell, luôn sử dụng `:paste` mode để tránh lỗi syntax.

### 4. Đọc CDC Topic từ Kafka

Sử dụng `:paste` mode để paste code đúng định dạng:

```
:paste
```

Rồi dán code này:

```scala
import org.apache.spark.sql.functions._
import org.apache.spark.sql.types._

val df = spark.readStream
  .format("kafka")
  .option("kafka.bootstrap.servers", "cdc-kafka:29092")
  .option("subscribe", "mysql.inventory.customers")
  .option("startingOffsets", "earliest")
  .load()

val schema = new StructType()
  .add("before", new StructType()
    .add("id", IntegerType)
    .add("name", StringType)
    .add("email", StringType)
    .add("created_at", StringType))
  .add("after", new StructType()
    .add("id", IntegerType)
    .add("name", StringType)
    .add("email", StringType)
    .add("created_at", StringType))
  .add("op", StringType)

val query = df.selectExpr("CAST(value AS STRING) as json")
  .select(get_json_object(col("json"), "$.payload").alias("payload"))
  .select(from_json(col("payload"), schema).alias("data"))
  .select("data.after.*")
  .writeStream
  .format("console")
  .option("truncate", false)
  .start()

query.awaitTermination()
```

Nhấn `Ctrl + D` để kết thúc `:paste` mode.

### 5. Kiểm Tra CDC Theo Thời Gian Thực

Mở một terminal khác và chèn dữ liệu kiểm tra:

```bash
docker exec -it cdc-mysql mysql -uroot -proot -e \
"USE inventory; INSERT INTO customers (name, email) VALUES ('TestUser', 'test@example.com');"
```

Bạn sẽ thấy sự kiện CDC xuất hiện trong đầu ra console của Spark.

### 6. Dừng Streaming

Nhấn:

```
Ctrl + C
```

## Cấu Hình

| Thuộc Tính | Giá Trị |
|----------|-------|
| **Topic** | `mysql.inventory.customers` |
| **CDC Format** | Debezium JSON Envelope |
| **Phiên Bản Spark** | 3.5.0 |
| **Phiên Bản Kafka Client** | 3.4.1 |
| **Kafka Bootstrap Servers** | `cdc-kafka:29092` |
| **Starting Offsets** | `earliest` |
| **Output Format** | Debezium JSON với payload extraction |

## Tính Năng

- Tiêu thụ CDC events từ Kafka theo thời gian thực (Structured Streaming)
- Parse định dạng Debezium JSON Envelope
- Extract `before` và `after` state từ CDC payload
- Real-time display dữ liệu thay đổi trên console
- Hỗ trợ multiple sinks: Console, MongoDB, Redis (tùy chỉnh)
- Exactly-once semantics và fault tolerance

## Quy Trình Git

Sau khi thực hiện các thay đổi trong module Spark, hãy commit riêng:

```bash
git add spark/
git commit -m "Add Spark Structured Streaming CDC consumer module"
git push
```

## Lưu Thay Đổi Trong Trình Soạn Thảo Nano

Nếu chỉnh sửa tệp bằng nano:

1. Nhấn: `Ctrl + O` (ghi ra)
2. Nhấn: `Enter` (xác nhận tên tệp)
3. Nhấn: `Ctrl + X` (thoát)

## Cấu Trúc Dự Án

```
spark/
├── README.md                              # Tệp này
├── docker-compose.yml                     # Định nghĩa Spark cluster
└── streaming/
    └── cdc_consumer.scala                 # Triển khai CDC consumer
```

## Khắc Phục Sự Cố

- **Giao diện Spark không truy cập được**: Đảm bảo cổng 8080 không bị chặn và các container đang chạy
- **Kết nối Kafka thất bại**: Xác minh hostname `cdc-kafka` và cổng `29092` (internal network port) đúng
- **Không xuất hiện sự kiện CDC**: Kiểm tra xem Debezium connector đang chạy và MySQL binlog được bật
- **Paste code gặp lỗi**: Luôn sử dụng `:paste` mode khi paste code vào spark-shell

## Tài Liệu Tham Khảo

- [Apache Spark Structured Streaming](https://spark.apache.org/docs/latest/structured-streaming-programming-guide.html)
- [Debezium MySQL Connector](https://debezium.io/documentation/reference/stable/connectors/mysql.html)
- [Kafka Integration for Spark](https://spark.apache.org/docs/latest/structured-streaming-kafka-integration.html)