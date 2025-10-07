ARG TAG=5.0.0
FROM apache/superset:${TAG}

USER root

# Instala os drivers DENTRO do venv usado pelo Superset
RUN /app/.venv/bin/python -m ensurepip --upgrade || true \
 && /app/.venv/bin/python -m pip install --upgrade pip setuptools wheel \
 && /app/.venv/bin/python -m pip install --no-cache-dir psycopg2-binary redis

# Config local
COPY superset_config.py /app/superset_config.py
# (alternativa sem SUPERSET_CONFIG_PATH)
# COPY superset_config.py /app/pythonpath/superset_config.py

USER superset
