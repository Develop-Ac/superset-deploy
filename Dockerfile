##############################################
# -------- Stage 1: Build do frontend --------
##############################################
ARG TAG=6.0.0rc2
FROM node:18-bullseye AS fe-build
ARG TAG
WORKDIR /src

RUN apt-get update && apt-get install -y --no-install-recommends \
    git python3 make g++ zstd \
 && rm -rf /var/lib/apt/lists/*

RUN git clone --branch ${TAG} --depth 1 https://github.com/apache/superset.git .
WORKDIR /src/superset-frontend

ENV NPM_CONFIG_LOGLEVEL=warn \
    NPM_CONFIG_FUND=false \
    NPM_CONFIG_AUDIT=false \
    NODE_OPTIONS=--max_old_space_size=4096

# Instala dependências normais
RUN --mount=type=cache,target=/root/.npm npm ci --legacy-peer-deps

# Instala manualmente dependências que o build exige mas não estão declaradas corretamente
RUN npm install --no-save \
    @react-spring/web \
    global-box \
    query-string \
    @deck.gl/widgets \
    @deck.gl/mesh-layers \
    @deck.gl/extensions

# Agora compila
RUN --mount=type=cache,target=/root/.npm npm run build

##############################################
# -------- Stage 2: Imagem final Superset ----
##############################################
FROM apache/superset:${TAG}
USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    unixodbc unixodbc-dev freetds-bin freetds-dev tdsodbc curl \
 && rm -rf /var/lib/apt/lists/*

RUN /app/.venv/bin/python -m ensurepip --upgrade || true \
 && /app/.venv/bin/python -m pip install --upgrade pip setuptools wheel \
 && /app/.venv/bin/python -m pip install --no-cache-dir \
    psycopg2-binary \
    pymssql \
    pyodbc \
    pillow \
    redis \
    Babel

RUN printf "[FreeTDS]\nDescription=FreeTDS Driver\nDriver=/usr/lib/x86_64-linux-gnu/odbc/libtdsodbc.so\nUsageCount=1\n" \
  > /etc/odbcinst.ini

COPY --from=fe-build /src/superset-frontend/dist/ /app/superset/static/assets/
COPY --from=fe-build /src/superset/translations/ /app/superset/translations/

RUN /app/.venv/bin/pybabel compile -d /app/superset/translations -l pt_BR || true

COPY superset_config.py /app/superset_config.py
ENV SUPERSET_CONFIG_PATH=/app/superset_config.py

HEALTHCHECK --interval=30s --timeout=5s --retries=10 CMD curl -fsS http://127.0.0.1:8088/health || exit 1

USER superset
