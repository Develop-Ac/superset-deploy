# Dockerfile
ARG TAG=5.0.0
FROM apache/superset:${TAG}

USER root

# SO deps (ODBC/FreeTDS)
RUN apt-get update && apt-get install -y --no-install-recommends \
    unixodbc unixodbc-dev freetds-bin freetds-dev \
 && rm -rf /var/lib/apt/lists/*

# Pacotes Python no venv do Superset
RUN /app/.venv/bin/python -m ensurepip --upgrade || true \
 && /app/.venv/bin/pip install --upgrade pip setuptools wheel \
 && /app/.venv/bin/pip install --no-cache-dir pyodbc pymssql

# (opcional) declarar o driver FreeTDS no odbcinst
RUN printf "[FreeTDS]\nDescription=FreeTDS Driver\nDriver=/usr/lib/x86_64-linux-gnu/odbc/libtdsodbc.so\nSetup=/usr/lib/x86_64-linux-gnu/odbc/libtdsS.so\nUsageCount=1\n" \
    > /etc/odbcinst.ini

# Seu config
COPY superset_config.py /app/superset_config.py
ENV SUPERSET_CONFIG_PATH=/app/superset_config.py

USER superset
