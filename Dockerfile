##############################################
# -------- Stage 1: Build do frontend --------
##############################################
ARG TAG=6.0.0rc2
FROM node:18-bullseye AS fe-build
ARG TAG
WORKDIR /src

# Instala dependências básicas para compilar o frontend
RUN apt-get update && apt-get install -y --no-install-recommends \
    git python3 make g++ zstd \
 && rm -rf /var/lib/apt/lists/*

# Clona o código-fonte da versão especificada do Superset
RUN git clone --branch ${TAG} --depth 1 https://github.com/apache/superset.git .
WORKDIR /src/superset-frontend

# Otimiza o build e garante memória suficiente para Node
ENV NPM_CONFIG_LOGLEVEL=warn \
    NPM_CONFIG_FUND=false \
    NPM_CONFIG_AUDIT=false \
    NODE_OPTIONS=--max_old_space_size=4096

# Instala dependências do frontend
RUN --mount=type=cache,target=/root/.npm npm ci

# 🔥 Compila o frontend incluindo o bundle de idioma pt_BR
RUN npm run build -- --locale=pt_BR

##############################################
# -------- Stage 2: Imagem final Superset ----
##############################################
FROM apache/superset:${TAG}
USER root

# Copia o build do frontend gerado no Stage 1
COPY --from=fe-build /src/superset-frontend /app/superset-frontend

# 1) Pacotes do SO (ODBC + FreeTDS)
RUN apt-get update && apt-get install -y --no-install-recommends \
    unixodbc unixodbc-dev freetds-bin freetds-dev tdsodbc \
 && rm -rf /var/lib/apt/lists/*

# 2) Garantir pip dentro do venv do Superset
RUN /app/.venv/bin/python -m ensurepip --upgrade || true \
 && /app/.venv/bin/python -m pip install --upgrade pip setuptools wheel

# 3) Drivers/bindings Python necessários
RUN /app/.venv/bin/python -m pip install --no-cache-dir \
    psycopg2-binary \
    pymssql \
    pyodbc \
    pillow \
    redis \
    Babel

# 4) Registrar driver FreeTDS no ODBC do sistema
RUN printf "[FreeTDS]\nDescription=FreeTDS Driver\nDriver=/usr/lib/x86_64-linux-gnu/odbc/libtdsodbc.so\nUsageCount=1\n" \
  > /etc/odbcinst.ini

# 5) Config do Superset (backend)
COPY superset_config.py /app/superset_config.py
ENV SUPERSET_CONFIG_PATH=/app/superset_config.py

# (Opcional) Healthcheck simples
HEALTHCHECK --interval=30s --timeout=3s --retries=10 \
  CMD curl -sf http://127.0.0.1:8088/health || exit 1

USER superset
