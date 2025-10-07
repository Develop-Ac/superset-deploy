import os

# Pega as variáveis de ambiente
DATABASE_HOST = os.environ.get("DATABASE_HOST")
DATABASE_PORT = os.environ.get("DATABASE_PORT")
DATABASE_USER = os.environ.get("DATABASE_USER")
DATABASE_PASSWORD = os.environ.get("DATABASE_PASSWORD")
DATABASE_DB = os.environ.get("DATABASE_DB")
REDIS_HOST = os.environ.get("REDIS_HOST")
REDIS_PORT = os.environ.get("REDIS_PORT")
SECRET_KEY = os.environ.get("SECRET_KEY")

# Constrói as URLs de conexão
SQLALCHEMY_DATABASE_URI = f"postgresql+psycopg2://{DATABASE_USER}:{DATABASE_PASSWORD}@{DATABASE_HOST}:{DATABASE_PORT}/{DATABASE_DB}"

# Configurações de Cache e Celery
CACHE_CONFIG = {
    'CACHE_TYPE': 'RedisCache',
    'CACHE_DEFAULT_TIMEOUT': 300,
    'CACHE_KEY_PREFIX': 'superset_',
    'CACHE_REDIS_URL': f'redis://{REDIS_HOST}:{REDIS_PORT}/0'
}

class CeleryConfig(object):
    broker_url = f"redis://{REDIS_HOST}:{REDIS_PORT}/1"
    imports = ('superset.sql_lab', )
    result_backend = f"redis://{REDIS_HOST}:{REDIS_PORT}/2"
    worker_prefetch_multiplier = 10
    task_acks_late = False

CELERY_CONFIG = CeleryConfig
