# -------- Imagem final do Superset (6.0.0rc1) --------
ARG TAG=6.0.0rc1
FROM apache/superset:${TAG}

USER root

# 1) Pacotes do SO (ODBC + FreeTDS)  — (mantido)
RUN apt-get update && apt-get install -y --no-install-recommends \
    unixodbc unixodbc-dev freetds-bin freetds-dev tdsodbc \
 && rm -rf /var/lib/apt/lists/*

# 2) Garantir pip dentro do venv do Superset — (mantido)
RUN /app/.venv/bin/python -m ensurepip --upgrade || true \
 && /app/.venv/bin/python -m pip install --upgrade pip setuptools wheel

# 3) Drivers/bindings Python necessários — (mantido)
RUN /app/.venv/bin/python -m pip install --no-cache-dir \
    psycopg2-binary \
    pymssql \
    pyodbc \
    pillow \
    redis \
    Babel

# 4) Registrar driver FreeTDS — (mantido)
RUN printf "[FreeTDS]\nDescription=FreeTDS Driver\nDriver=/usr/lib/x86_64-linux-gnu/odbc/libtdsodbc.so\nUsageCount=1\n" \
  > /etc/odbcinst.ini

# 5) Config do Superset — (mantido)
COPY superset_config.py /app/superset_config.py
ENV SUPERSET_CONFIG_PATH=/app/superset_config.py

USER superset
