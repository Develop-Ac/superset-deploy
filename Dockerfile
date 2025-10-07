# Escolha uma tag estável (ex.: 6.0.0)
FROM apache/superset:5.0.0

USER root
# Ative o venv da imagem e instale os pacotes necessários
# (psycopg2-binary = Postgres do metastore; redis = cache/celery)
RUN . /app/.venv/bin/activate && \
    pip install --no-cache-dir psycopg2-binary redis

USER superset
# Mantém o entrypoint padrão: run-server (Gunicorn) na 8088
CMD ["/app/docker/entrypoints/run-server.sh"]
