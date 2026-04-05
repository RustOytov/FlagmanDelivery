# Агрегатор доставки (FastAPI)

## Запуск в Docker

```bash
docker compose up -d
```

Сервис API: [http://localhost:8000](http://localhost:8000)

- **Swagger UI:** [http://localhost:8000/docs](http://localhost:8000/docs)
- **WebSocket:** `ws://localhost:8000/ws/{token}` (подставьте JWT из ответа `POST /api/auth/login`)

Переменные окружения задаются в `.env`. Для `docker compose` хост БД в `DATABASE_URL` переопределяется в `docker-compose.yml` на сервис `postgres`.

Локальный запуск без Docker: в `.env` укажите `DATABASE_URL=postgresql+psycopg2://postgres:postgres@localhost:5432/delivery` и поднимите PostgreSQL с PostGIS.

## Разработка

```bash
pip install -r requirements.txt
uvicorn main:app --reload
```
