# Troque TAG se for usar outra (ex.: 5.0.0)
ARG TAG=5.0.0
FROM apache/superset:${TAG}

USER root

# Instala drivers no Python da imagem (sem depender de venv específico)
RUN python -m pip install --no-cache-dir psycopg2-binary redis

# (Opcional) Aqui você pode incluir outros drivers que for usar:
# RUN python -m pip install --no-cache-dir pymssql sqlalchemy-bigquery snowflake-sqlalchemy ...

# Copie sua config
COPY superset_config.py /app/superset_config.py

# (Opcional) Em vez de usar SUPERSET_CONFIG_PATH, você pode já colocar no pythonpath:
# COPY superset_config.py /app/pythonpath/superset_config.py

USER superset
# entrypoint padrão do Superset já sobe o gunicorn na 8088
