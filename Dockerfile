FROM apache/superset:5.0.0

USER root

# 1) Dependências de sistema (toolchain, FreeTDS, ODBC)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
    g++ \
    make \
    pkg-config \
    libpq-dev \
    freetds-dev \
    freetds-bin \
    libssl-dev \
    libkrb5-dev \
    unixodbc \
    unixodbc-dev \
    curl \
    gnupg \
    ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# 2) (Opcional) MS ODBC Driver 18 (para também poder usar pyodbc)
RUN . /etc/os-release && \
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
      | gpg --dearmor -o /usr/share/keyrings/ms-prod.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/ms-prod.gpg] https://packages.microsoft.com/${ID}/${VERSION_ID%%.*}/prod ${VERSION_CODENAME} main" \
      > /etc/apt/sources.list.d/mssql-release.list && \
    apt-get update && ACCEPT_EULA=Y apt-get install -y msodbcsql18 && \
    rm -rf /var/lib/apt/lists/*

# 3) Bootstrapa o pip dentro do venv do Superset e instala os drivers
RUN /app/.venv/bin/python -m ensurepip --upgrade || true && \
    (command -v /app/.venv/bin/pip >/dev/null || /app/.venv/bin/python -m ensurepip --upgrade) || true && \
    (command -v /app/.venv/bin/pip >/dev/null || (apt-get update && apt-get install -y --no-install-recommends python3-pip && rm -rf /var/lib/apt/lists/*)) && \
    /app/.venv/bin/python -m pip install --upgrade pip setuptools wheel && \
    /app/.venv/bin/python -m pip install --no-cache-dir \
        psycopg2-binary \
        pymssql \
        pyodbc \
        redis

# [CORRIGIDO] Cria o diretório /etc/odbc ANTES de escrever o arquivo de configuração.
RUN mkdir -p /etc/odbc && \
    printf "[FreeTDS]\nDescription=FreeTDS Driver\nDriver=/usr/lib/x86_64-linux-gnu/odbc/libtdsodbc.so\nUsageCount=1\n" \
    > /etc/odbc/odbcinst.ini

# 4) Config do Superset (se houver)
COPY superset_config.py /app/superset_config.py
ENV SUPERSET_CONFIG_PATH=/app/superset_config.py

# 5) Healthcheck
HEALTHCHECK --interval=30s --timeout=5s --retries=10 \
  CMD curl -fsS http://127.0.0.1:8088/health || exit 1

USER superset
