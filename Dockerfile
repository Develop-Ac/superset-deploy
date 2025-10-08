# Dockerfile
ARG TAG=5.0.0
FROM apache/superset:${TAG}

USER root

# SO deps (ODBC/FreeTDS + driver ODBC do FreeTDS)
RUN apt-get update && apt-get install -y --no-install-recommends \
    unixodbc unixodbc-dev freetds-bin freetds-dev tdsodbc \
 && rm -rf /var/lib/apt/lists/*

# Pacotes Python dentro do venv do Superset (use sempre python -m pip)
RUN /app/.venv/bin/python -m ensurepip --upgrade || true \
 && /app/.venv/bin/python -m pip install --upgrade pip setuptools wheel \
 && /app/.venv/bin/python -m pip install --no-cache-dir pyodbc pymssql

# (opcional) registrar driver no odbcinst (ajuda o pyodbc a encontrar)
RUN printf "[FreeTDS]\nDescription=FreeTDS Driver\nDriver=/usr/lib/x86_64-linux-gnu/odbc/libtdsodbc.so\nUsageCount=1\n" \
    > /etc/odbcinst.ini

# Seu config
COPY superset_config.py /app/superset_config.py
ENV SUPERSET_CONFIG_PATH=/app/superset_config.py

USER superset
