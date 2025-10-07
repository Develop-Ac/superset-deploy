# Escolha uma tag estável
FROM apache/superset:5.0.0

USER root
# Copia o arquivo de configuração
COPY superset_config.py /app/

# Instala os pacotes necessários
RUN . /app/.venv/bin/activate && \
    pip install --no-cache-dir psycopg2-binary redis

USER superset
# Mantém o entrypoint padrão
CMD ["/app/docker/entrypoints/run-server.sh"]
