# Troque TAG se for usar outra (ex.: 5.0.0)
ARG TAG=5.0.0
FROM apache/superset:${TAG}

USER root
# Instala no venv que o Superset usa em runtime
RUN /app/.venv/bin/pip install --no-cache-dir psycopg2-binary redis

# Se for usar MSSQL/BigQuery etc., instale aqui os outros drivers:
# RUN /app/.venv/bin/pip install --no-cache-dir pymssql sqlalchemy-bigquery ...

COPY superset_config.py /app/superset_config.py

USER superset
# entrypoint padrão já inicia o gunicorn na 8088
