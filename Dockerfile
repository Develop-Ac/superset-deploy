# =========================================
# Stage 1: Build do frontend (Superset 6.x)
# =========================================
ARG TAG=6.0.0rc2
FROM node:18-bullseye AS fe-build
WORKDIR /src

# Ferramentas nativas + zstd (requerido em alguns passos de build)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git python3 make g++ zstd curl ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Garante uso do registry público do npm (evita ETARGET por mirror incompleto)
RUN npm config set registry https://registry.npmjs.org/

# Clona exatamente a tag desejada do Superset para um diretório novo
RUN git clone --branch ${TAG} --depth 1 https://github.com/apache/superset.git /src/superset

# Ativa yarn classic e respeita o lockfile do projeto
RUN corepack enable && corepack prepare yarn@1.22.22 --activate

# Vai para o diretório do frontend
WORKDIR /src/superset/superset-frontend

ENV NODE_OPTIONS=--max_old_space_size=4096 \
    YARN_ENABLE_IMMUTABLE_INSTALLS=false

# Instala dependências conforme yarn.lock (com cache)
RUN --mount=type=cache,target=/root/.yarn \
    --mount=type=cache,target=/root/.cache/yarn \
    yarn install --frozen-lockfile

# Compila (pt_BR já vem incluído no 6.x)
RUN --mount=type=cache,target=/root/.yarn \
    --mount=type=cache,target=/root/.cache/yarn \
    yarn build


# =========================================
# Stage 2: Imagem final do Superset
# =========================================
ARG TAG=6.0.0rc2
FROM apache/superset:${TAG}

USER root

# 1) Pacotes do SO (ODBC + FreeTDS) + curl p/ healthcheck
RUN apt-get update && apt-get install -y --no-install-recommends \
    unixodbc unixodbc-dev freetds-bin freetds-dev tdsodbc \
    curl ca-certificates \
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

# 5) Copiar assets do frontend já compilados
COPY --from=fe-build /src/superset/superset-frontend/dist/ /app/superset/static/assets/

# 6) Copiar suas configs
COPY superset_config.py /app/superset_config.py
ENV SUPERSET_CONFIG_PATH=/app/superset_config.py

# (Opcional) Healthcheck simples
HEALTHCHECK --interval=30s --timeout=3s --retries=10 CMD curl -sf http://127.0.0.1:8088/health || exit 1

USER superset
