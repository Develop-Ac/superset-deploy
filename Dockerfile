# ---- Stage 1: build do frontend com i18n (pt_BR) ----
FROM node:18-bullseye AS fe-build
ARG TAG=5.0.0
WORKDIR /src

# Baixa o código da mesma versão do runtime
RUN apt-get update && apt-get install -y --no-install-recommends git python3 python3-pip \
  && rm -rf /var/lib/apt/lists/*
RUN git clone --branch ${TAG} --depth 1 https://github.com/apache/superset.git .

# Instala dependências e gera os bundles
WORKDIR /src/superset-frontend
RUN npm ci
# O build inclui os arquivos de tradução disponíveis (pt_BR já vem no repo)
RUN npm run build

# ---- Stage 2: imagem final (a sua base) ----
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

# 3) Drivers/bindings Python
RUN /app/.venv/bin/python -m pip install --no-cache-dir \
    psycopg2-binary \
    pymssql \
    pyodbc \
    pillow \
    redis \
    Babel

# 4) Registrar o driver FreeTDS no ODBC do sistema
RUN printf "[FreeTDS]\nDescription=FreeTDS Driver\nDriver=/usr/lib/x86_64-linux-gnu/odbc/libtdsodbc.so\nUsageCount=1\n" \
  > /etc/odbcinst.ini

# 5) Copiar assets do frontend e traduções do backend da Stage 1
#    (o build coloca os artefatos em superset-frontend/dist)
COPY --from=fe-build /src/superset-frontend/dist/ /app/superset/static/assets/
COPY --from=fe-build /src/superset/translations/ /app/superset/translations/

# 6) Compilar .po -> .mo do backend (pt_BR)
RUN /app/.venv/bin/pybabel compile -d /app/superset/translations -l pt_BR || true

# 7) Suas configs do Superset
COPY superset_config.py /app/superset_config.py
ENV SUPERSET_CONFIG_PATH=/app/superset_config.py

USER superset
