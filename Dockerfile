# -------- Imagem final do Superset (6.0.0rc1) --------
# Observação: nesta abordagem NÃO recompilamos o frontend.
# O Superset 6 já vem com bundles de idioma prontos (inclui pt_BR).
ARG TAG=6.0.0rc2
FROM apache/superset:${TAG}

USER root

# 1) Pacotes do SO (ODBC + FreeTDS)
RUN apt-get update && apt-get install -y --no-install-recommends \
    unixodbc unixodbc-dev freetds-bin freetds-dev tdsodbc \
 && rm -rf /var/lib/apt/lists/*

# 2) Garantir pip dentro do venv do Superset
RUN /app/.venv/bin/python -m ensurepip --upgrade || true \
 && /app/.venv/bin/python -m pip install --upgrade pip setuptools wheel

# 3) Drivers/bindings Python necessários
RUN /app/.venv/bin/python -m pip install --no-cache-dir \
    psycopg2-binary \
    pymssql \
    pyodbc \
    pillow \
    redis \
    Babel

# 4) Registrar driver FreeTDS no ODBC do sistema
RUN printf "[FreeTDS]\nDescription=FreeTDS Driver\nDriver=/usr/lib/x86_64-linux-gnu/odbc/libtdsodbc.so\nUsageCount=1\n" \
  > /etc/odbcinst.ini

# 5) Config do Superset
COPY superset_config.py /app/superset_config.py
ENV SUPERSET_CONFIG_PATH=/app/superset_config.py

# (Opcional) Healthcheck simples
HEALTHCHECK --interval=30s --timeout=3s --retries=10 CMD curl -sf http://127.0.0.1:8088/health || exit 1

USER superset
