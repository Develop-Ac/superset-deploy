# Superset 5.0.0 com Postgres (psycopg2) + SQL Server (pymssql + opcional pyodbc/ODBC18)
FROM apache/superset:5.0.0

USER root

# Bash como shell para poder 'source' o venv
SHELL ["/bin/bash", "-lc"]

# 1) Toolchain e libs de sistema
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential gcc g++ make pkg-config \
    libpq-dev \
    freetds-dev freetds-bin \        # para pymssql (FreeTDS)
    libssl-dev libkrb5-dev \
    unixodbc unixodbc-dev \          # base ODBC
    curl gnupg ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# 2) (Opcional) MS ODBC Driver 18 — para usar também mssql+pyodbc
#    Se não quiser pyodbc/ODBC, COMENTE este bloco.
RUN . /etc/os-release && \
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
      | gpg --dearmor -o /usr/share/keyrings/ms-prod.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/ms-prod.gpg] https://packages.microsoft.com/${ID}/${VERSION_ID%%.*}/prod ${VERSION_CODENAME} main" \
      > /etc/apt/sources.list.d/mssql-release.list && \
    apt-get update && ACCEPT_EULA=Y apt-get install -y msodbcsql18 && \
    rm -rf /var/lib/apt/lists/*

# 3) Instalar drivers Python usando UV (a imagem v5 já traz o /app/.venv)
#    Importante: NÃO usar pip aqui.
RUN source /app/.venv/bin/activate && \
    uv pip install --no-cache-dir \
      psycopg2-binary \
      pymssql \
      pyodbc \
      redis

# (Opcional) Registrar o FreeTDS no ODBC — útil para testes via isql/pyodbc
RUN printf "[FreeTDS]\nDescription=FreeTDS Driver\nDriver=/usr/lib/x86_64-linux-gnu/odbc/libtdsodbc.so\nUsageCount=1\n" \
  > /etc/odbc/odbcinst.ini

# 4) Config do Superset (se você tiver)
COPY superset_config.py /app/superset_config.py
ENV SUPERSET_CONFIG_PATH=/app/superset_config.py

# 5) Healthcheck
HEALTHCHECK --interval=30s --timeout=5s --retries=10 \
  CMD curl -fsS http://127.0.0.1:8088/health || exit 1

USER superset
