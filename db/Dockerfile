FROM postgres:17-bookworm

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-venv python3-dev gcc libpq-dev curl gettext-base \
    && python3 -m venv /opt/venv \
    && /opt/venv/bin/pip install --no-cache-dir --upgrade pip \
    && /opt/venv/bin/pip install patroni[consul] psycopg2-binary \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN useradd -ms /bin/bash patroni

WORKDIR /home/patroni

COPY patroni-template.yml /home/patroni/patroni-template.yml
COPY entrypoint.sh /home/patroni/entrypoint.sh

RUN mkdir -p /home/patroni/pgdata && \
    chmod +x /home/patroni/entrypoint.sh && \
    chown -R patroni:patroni /home/patroni

USER patroni

EXPOSE 5432 8008

ENV PATH="/opt/venv/bin:$PATH"
CMD ["/home/patroni/entrypoint.sh"]
