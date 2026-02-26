FROM apache/spark:3.5.0

USER root

# Tạo ivy cache chuẩn
RUN mkdir -p /home/spark/.ivy2 && \
    chown -R spark:spark /home/spark/.ivy2

USER spark
