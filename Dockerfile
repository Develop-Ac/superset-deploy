# Dockerfile otimizado para deploy via EasyPanel com a versão estável 5.0.0
# Baseado na imagem oficial, que já tem o frontend pré-compilado e traduções inclusas.
FROM apache/superset:5.0.0

# Troca para o usuário root para poder instalar pacotes do sistema.
USER root

# 1) Instala os drivers ODBC para conexão com SQL Server (via FreeTDS) e o curl para o healthcheck.
RUN apt-get update && apt-get install -y --no-install-recommends \
    unixodbc unixodbc-dev freetds-bin freetds-dev tdsodbc curl \
 && rm -rf /var/lib/apt/lists/*

# 2) Instala os drivers Python para seus bancos de dados (Postgres, SQL Server, etc.).
RUN /app/.venv/bin/python -m pip install --no-cache-dir \
    psycopg2-binary \
    pymssql \
    pyodbc \
    redis

# 3) Configura o driver FreeTDS para ser reconhecido pelo sistema ODBC.
RUN printf "[FreeTDS]\nDescription=FreeTDS Driver\nDriver=/usr/lib/x86_64-linux-gnu/odbc/libtdsodbc.so\nUsageCount=1\n" \
  > /etc/odbc/odbcinst.ini

# 4) Copia o arquivo de configuração customizado para dentro da imagem.
COPY superset_config.py /app/superset_config.py

# 5) Define a variável de ambiente para que o Superset encontre sua configuração.
ENV SUPERSET_CONFIG_PATH=/app/superset_config.py

# 6) Healthcheck padrão para o EasyPanel monitorar a saúde do container.
HEALTHCHECK --interval=30s --timeout=5s --retries=10 CMD curl -fsS http://127.0.0.1:8088/health || exit 1

# 7) Retorna para o usuário 'superset' por questões de segurança.
USER superset
