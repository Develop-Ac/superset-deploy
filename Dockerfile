# Dockerfile
ARG TAG=5.0.0
FROM apache/superset:${TAG}

USER root

# =========================
# 1) Instalar dependências do sistema
# =========================
RUN apt-get update && apt-get install -y --no-install-recommends \
    unixodbc unixodbc-dev freetds-bin freetds-dev tdsodbc \
 && rm -rf /var/lib/apt/lists/*

# =========================
# 2) Garantir que o venv tenha pip
# =========================
RUN /app/python_env/bin/python -m ensurepip --upgrade || true \
 && /app/python_env/bin/python -m pip install --upgrade pip setuptools wheel

# =========================
# 3) Instalar pacotes Python necessários
# =========================
RUN /app/python_env/bin/python -m pip install --no-cache-dir \
    psycopg2-binary \
    pymssql \
    pyodbc \
    pillow \
    redis

# =========================
# 4) Registrar o driver FreeTDS no sistema ODBC
# =========================
RUN printf "[FreeTDS]\nDescription=FreeTDS Driver\nDriver=/usr/lib/x86_64-linux-gnu/odbc/libtdsodbc.so\nUsageCount=1\n" \
    > /etc/odbcinst.ini

# =========================
# 5) Copiar configurações customizadas do Superset
# =========================
COPY superset_config.py /app/superset_config.py
ENV SUPERSET_CONFIG_PATH=/app/superset_config.py

USER superset
