# Superset 5.0.0 com Postgres + SQL Server (pymssql + opcional pyodbc/ODBC18)
FROM apache/superset:5.0.0

USER root

# 1) Toolchain e libs necessárias p/ psycopg2, pymssql e (opcional) pyodbc
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential gcc g++ make pkg-config \
    libpq-dev \
    freetds-dev freetds-bin \
    libssl-dev libkrb5-dev \
    unixodbc unixodbc-dev \
    curl gnupg ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# 2) (Opcional) Instalar ODBC Driver 18 da Microsoft (para também usar mssql+pyodbc)
#    Se não quiser pyodbc, pode comentar este bloco.
RUN set -eux; \
    . /etc/os-release; \
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
      | gpg --dearmor -o /usr/share/keyrings/ms-prod.gpg; \
    echo "deb [signed-by=/usr/share/keyrings/ms-prod.gpg] https://packages.microsoft.com/debian/${VERSION_CODENAME}/prod ${VERSION_CODENAME} main" \
      > /etc/apt/sources.list.d/mssql-release.list; \
    apt-get update; \
    ACCEPT_EULA=Y apt-get install -y msodbcsql18; \
    rm -rf /var/lib/apt/lists/*

# 3) Atualiza pip do venv do Superset (evita bugs de build)
RUN /app/.venv/bin/python -m pip install --upgrade pip

# 4) Drivers Python
#    Se o seu ambiente insistir em compilar o pymssql, você pode descomentar a linha:
#    ENV PYMSSQL_BUILD_WITH_BUNDLED_FREETDS=1
RUN /app/.venv/bin/python -m pip install --no-cache-dir \
    psycopg2-binary \
    pymssql \
    pyodbc \
    redis

# (Opcional) Registrar o driver FreeTDS no odbcinst.ini (útil para testes via isql/pyodbc)
RUN printf "[FreeTDS]\nDescription=FreeTDS Driver\nDriver=/usr/lib/x86_64-linux-gnu/odbc/libtdsodbc.so\nUsageCount=1\n" \
  > /etc/odbc/odbcinst.ini

# 5) Config do Superset (se você tiver um superset_config.py local)
COPY superset_config.py /app/superset_config.py
ENV SUPERSET_CONFIG_PATH=/app/superset_config.py

# 6) Healthcheck p/ EasyPanel
HEALTHCHECK --interval=30s --timeout=5s --retries=10 \
  CMD curl -fsS http://127.0.0.1:8088/health || exit 1

USER superset
