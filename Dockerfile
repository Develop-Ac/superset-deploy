##############################################
# ---------- Stage 1: fe-build --------------
##############################################
ARG TAG=6.0.0rc2
FROM node:18-bullseye AS fe-build
ARG TAG
WORKDIR /src

# deps nativas para compilar addons / zstd (simple-zstd)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git python3 make g++ zstd \
 && rm -rf /var/lib/apt/lists/*

# pega o código da versão TAG
RUN git clone --branch ${TAG} --depth 1 https://github.com/apache/superset.git .
WORKDIR /src/superset-frontend

# ambiente npm
ENV NPM_CONFIG_LOGLEVEL=warn \
    NPM_CONFIG_FUND=false \
    NPM_CONFIG_AUDIT=false \
    NODE_OPTIONS=--max_old_space_size=4096

# instala dependências travadas no lock do projeto
RUN --mount=type=cache,target=/root/.npm npm ci --legacy-peer-deps --quiet

# instala explicitamente os pacotes que o webpack reclamou (com versões estáveis)
# OBS: usamos --legacy-peer-deps para não travar em peer deps
RUN npm install --no-save --legacy-peer-deps --quiet \
    @react-spring/web@9.7.2 \
    global-box@1.0.0 \
    query-string@7.1.1 

# compila o bundle (inclui os idiomas padrão do 6.x; pt_BR já vem)
RUN --mount=type=cache,target=/root/.npm npm run build

##############################################
# ---------- Stage 2: imagem final ----------
##############################################
# mesma TAG do fe-build para manter compatibilidade
FROM apache/superset:${TAG}
USER root

# 1) Pacotes do SO (ODBC + FreeTDS) + curl p/ healthcheck
RUN apt-get update && apt-get install -y --no-install-recommends \
    unixodbc unixodbc-dev freetds-bin freetds-dev tdsodbc curl \
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

# 5) Copiar os assets compilados e traduções do fe-build
COPY --from=fe-build /src/superset-frontend/dist/ /app/superset/static/assets/
COPY --from=fe-build /src/superset/translations/ /app/superset/translations/

# 6) Gera .mo (i18n backend); se já existir, ignora
RUN /app/.venv/bin/pybabel compile -d /app/superset/translations -l pt_BR || true

# 7) Config do Superset
COPY superset_config.py /app/superset_config.py
ENV SUPERSET_CONFIG_PATH=/app/superset_config.py

# Healthcheck simples
HEALTHCHECK --interval=30s --timeout=5s --retries=10 CMD curl -fsS http://127.0.0.1:8088/health || exit 1

USER superset
