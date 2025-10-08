# -------- Stage 1: build do frontend com i18n (pt_BR) --------
# Usamos o mesmo TAG do Superset que vamos rodar
ARG TAG=6.0.0rc2
FROM node:20-bullseye AS fe-build
ARG TAG
WORKDIR /src

# zstd é necessário pro simple-zstd (webpack.proxy-config)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git python3 make g++ zstd \
 && rm -rf /var/lib/apt/lists/*

# Baixa o código do Superset na tag escolhida
RUN git clone --branch ${TAG} --depth 1 https://github.com/apache/superset.git .
WORKDIR /src/superset-frontend

# Evita travar no webpack e acelera o build
ENV NPM_CONFIG_LOGLEVEL=warn NPM_CONFIG_FUND=false NPM_CONFIG_AUDIT=false \
    PUPPETEER_SKIP_DOWNLOAD=1 \
    NODE_OPTIONS=--max_old_space_size=8192

# Instala dependências e compila
RUN --mount=type=cache,target=/root/.npm npm ci --legacy-peer-deps
RUN --mount=type=cache,target=/root/.npm npm run build

# -------- Stage 2: imagem final do Superset --------
# IMPORTANTE: TAG do runtime = 6.0.0rc1
ARG TAG=6.0.0rc1
FROM apache/superset:${TAG}

USER root

# 1) Pacotes do SO (ODBC + FreeTDS)  — (mantido)
RUN apt-get update && apt-get install -y --no-install-recommends \
    unixodbc unixodbc-dev freetds-bin freetds-dev tdsodbc \
 && rm -rf /var/lib/apt/lists/*

# 2) Garantir pip dentro do venv do Superset — (mantido)
RUN /app/.venv/bin/python -m ensurepip --upgrade || true \
 && /app/.venv/bin/python -m pip install --upgrade pip setuptools wheel

# 3) Drivers/bindings Python necessários — (mantido)
RUN /app/.venv/bin/python -m pip install --no-cache-dir \
    psycopg2-binary \
    pymssql \
    pyodbc \
    pillow \
    redis \
    Babel

# 4) Registrar driver FreeTDS — (mantido)
RUN printf "[FreeTDS]\nDescription=FreeTDS Driver\nDriver=/usr/lib/x86_64-linux-gnu/odbc/libtdsodbc.so\nUsageCount=1\n" \
  > /etc/odbcinst.ini

# 5) Copiar assets do frontend gerados (caminho correto no Superset 6)
#    O build gera em superset-frontend/static/assets/
COPY --from=fe-build /src/superset-frontend/static/assets/ /app/superset/static/assets/

# 6) (Opcional) sobrescrever traduções backend (já vêm na base; mantenho sua intenção)
COPY --from=fe-build /src/superset/translations/ /app/superset/translations/

# 7) Compilar .po -> .mo (backend i18n)
RUN /app/.venv/bin/pybabel compile -d /app/superset/translations -l pt_BR || true

# 8) Config do Superset — (mantido)
COPY superset_config.py /app/superset_config.py
ENV SUPERSET_CONFIG_PATH=/app/superset_config.py

USER superset
