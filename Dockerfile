ARG TAG=5.0.0
FROM apache/superset:${TAG}

USER root

# Instala os drivers DENTRO do venv usado pelo Superset
RUN /app/.venv/bin/python -m ensurepip --upgrade || true \
 && /app/.venv/bin/python -m pip install --upgrade pip setuptools wheel \
 && /app/.venv/bin/python -m pip install --no-cache-dir psycopg2-binary redis
 
# Dependências do ODBC
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl gnupg2 ca-certificates apt-transport-https unixodbc unixodbc-dev \
 && rm -rf /var/lib/apt/lists/*

# Repositório MS ODBC Driver 18 (para Debian 12 "bookworm"; se sua base for bullseye, troque o codename)
RUN curl -sSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg \
 && echo "deb [signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/debian/12/prod bookworm main" > /etc/apt/sources.list.d/mssql-release.list \
 && apt-get update \
 && ACCEPT_EULA=Y apt-get install -y msodbcsql18 \
 && rm -rf /var/lib/apt/lists/*

# Instala o conector Python
RUN /app/.venv/bin/python -m pip install --no-cache-dir pyodbc

# Config local
COPY superset_config.py /app/superset_config.py
# (alternativa sem SUPERSET_CONFIG_PATH)
# COPY superset_config.py /app/pythonpath/superset_config.py

USER superset
