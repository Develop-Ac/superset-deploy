ARG TAG=5.0.0
FROM apache/superset:${TAG}

USER root

# Instala os drivers dentro do venv usado em runtime pelo Superset
RUN /app/.venv/bin/python -m ensurepip --upgrade || true \
 && /app/.venv/bin/pip install --upgrade pip setuptools wheel \
 && /app/.venv/bin/pip install --no-cache-dir psycopg2-binary redis

# Sua config
COPY superset_config.py /app/superset_config.py
# (se preferir não usar SUPERSET_CONFIG_PATH, copie em pythonpath:)
# COPY superset_config.py /app/pythonpath/superset_config.py

USER superset
