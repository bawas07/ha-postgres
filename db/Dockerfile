FROM postgres:17-bookworm

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-pip python3-dev gcc libpq-dev curl \
 && pip3 install --no-cache-dir --upgrade pip \
 && pip3 install patroni[consul] psycopg2-binary \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN useradd -ms /bin/bash patroni
USER patroni
WORKDIR /home/patroni

EXPOSE 5432 8008

CMD ["patroni", "/home/patroni/patroni.yml"]

