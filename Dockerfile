# -------- Stage 1: build do frontend com i18n (pt_BR) --------
# Declare TAG aqui também para usar no git clone
ARG TAG=6.0.0rc1
FROM node:18-bullseye AS fe-build
ARG TAG
WORKDIR /src

# + zstd (necessário p/ simple-zstd usado no webpack.proxy-config)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git python3 make g++ zstd \
 && rm -rf /var/lib/apt/lists/*

RUN git clone --branch ${TAG} --depth 1 https://github.com/apache/superset.git .
WORKDIR /src/superset-frontend

# (opcional, ajuda performance/estabilidade)
ENV NPM_CONFIG_LOGLEVEL=warn NPM_CONFIG_FUND=false NPM_CONFIG_AUDIT=false \
    NODE_OPTIONS=--max_old_space_size=2048

RUN --mount=type=cache,target=/root/.npm npm ci
RUN --mount=type=cache,target=/root/.npm npm run build

# -------- Stage 2: imagem final do Superset --------
# IMPORTANTE: declarar o ARG antes do FROM
ARG TAG=5.0.0
FROM apache/superset:${TAG}

USER root

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

# 4) Registrar driver FreeTDS
RUN printf "[FreeTDS]\nDescription=FreeTDS Driver\nDriver=/usr/lib/x86_64-linux-gnu/odbc/libtdsodbc.so\nUsageCount=1\n" \
  > /etc/odbcinst.ini

# 5) Copiar assets do frontend e traduções
COPY --from=fe-build /src/superset-frontend/dist/ /app/superset/static/assets/
COPY --from=fe-build /src/superset/translations/ /app/superset/translations/

# 6) Compilar .po -> .mo (backend i18n)
RUN /app/.venv/bin/pybabel compile -d /app/superset/translations -l pt_BR || true

# 7) Config do Superset
COPY superset_config.py /app/superset_config.py
ENV SUPERSET_CONFIG_PATH=/app/superset_config.py

USER superset
