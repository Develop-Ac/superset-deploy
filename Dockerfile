# Troque TAG se for usar outra (ex.: 5.0.0)
ARG TAG=5.0.0
FROM apache/superset:${TAG}

USER root
# Ativa o venv da imagem e instala drivers essenciais
RUN . /app/.venv/bin/activate && \
    pip install --no-cache-dir psycopg2-binary redis

# Copie o config para um local fácil e aponte via env
COPY superset_config.py /app/superset_config.py

USER superset
# (entrypoint padrão já sobe gunicorn na 8088)
