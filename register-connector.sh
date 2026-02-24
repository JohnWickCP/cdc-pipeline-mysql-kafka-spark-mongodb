#!/bin/bash

curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d '{
    "name": "mysql-cdc-connector",
    "config": {
      "connector.class": "io.debezium.connector.mysql.MySqlConnector",
      "database.hostname": "cdc-mysql",
      "database.port": 3306,
      "database.user": "root",
      "database.password": "root123",
      "database.server.id": 184054,
      "database.server.name": "mysql-cdc-server",
      "database.include.list": "testdb",
      "table.include.list": "testdb.orders,testdb.customers",
      "database.history.kafka.bootstrap.servers": "cdc-kafka:29092",
      "database.history.kafka.topic": "dbhistory.testdb",
      "snapshot.mode": "when_needed"
    }
  }'

echo ""
echo "Connector registration sent"
