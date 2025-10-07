ARG TAG=5.0.0
FROM apache/superset:${TAG}

USER root

# Garante pip no Python do sistema e instala drivers no ambiente que o Superset usa
RUN /usr/local/bin/python -m ensurepip --upgrade || true \
 && /usr/local/bin/python -m pip install --upgrade pip setuptools wheel \
 && /usr/local/bin/python -m pip install --no-cache-dir psycopg2-binary redis

# Copie sua config; use UMA das duas opções abaixo:

# Opção 1) Usar SUPERSET_CONFIG_PATH em runtime
COPY superset_config.py /app/superset_config.py

# Opção 2) (alternativa) colocar direto no pythonpath e NÃO usar SUPERSET_CONFIG_PATH
# COPY superset_config.py /app/pythonpath/superset_config.py

USER superset
# entrypoint padrão já sobe gunicorn na 8088
