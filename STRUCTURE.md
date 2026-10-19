# Структура проекта

```
matrix-synapse-docker/
│
├── 📄 docker-compose.yml          # Основная конфигурация Docker Compose
│   ├── PostgreSQL (база данных)
│   ├── Synapse (Matrix сервер)
│   ├── Nginx (reverse proxy)
│   └── Certbot (SSL сертификаты)
│
├── ⚙️ .env.example                # Шаблон конфигурации
│   ├── DOMAIN                     # Ваш домен
│   ├── POSTGRES_PASSWORD          # Пароль БД
│   ├── SSL_EMAIL                  # Email для SSL
│   └── ADMIN_USERNAME/PASSWORD    # Данные администратора
│
├── 🚀 install.sh                  # Главный установочный скрипт
│   ├── Проверка системы
│   ├── Установка Docker
│   ├── Настройка служб
│   ├── Получение SSL
│   └── Создание администратора
│
├── 📚 Документация
│   ├── README.md                  # Полная документация
│   ├── QUICKSTART.md              # Быстрый старт (5 минут)
│   ├── FAQ.md                     # Частые вопросы
│   ├── CONTRIBUTING.md            # Гайд для контрибьюторов
│   └── STRUCTURE.md               # Этот файл
│
├── 🔧 nginx/                      # Конфигурация Nginx
│   ├── nginx.conf                 # Основной конфиг
│   └── matrix.conf                # Конфиг для Matrix
│       ├── HTTP (порт 80)
│       ├── HTTPS (порт 443)
│       └── Federation (порт 8448)
│
├── 🛠️ scripts/                    # Утилиты управления
│   ├── create-user.sh             # Создание пользователей
│   ├── backup.sh                  # Бэкап данных
│   ├── restore.sh                 # Восстановление
│   ├── status.sh                  # Проверка статуса
│   ├── setup-ssl.sh               # Настройка SSL
│   └── update.sh                  # Обновление Synapse
│
├── 🔒 certbot/                    # SSL сертификаты (создается при установке)
│   ├── conf/                      # Конфигурация
│   └── www/                       # Webroot для ACME challenge
│
├── 💾 Docker Volumes (создаются автоматически)
│   ├── postgres_data/             # База данных PostgreSQL
│   └── synapse_data/              # Данные Synapse
│       ├── homeserver.yaml        # Конфиг Synapse
│       ├── media_store/           # Загруженные файлы
│       └── keys/                  # Ключи шифрования
│
├── 📦 backups/                    # Бэкапы (создается при первом бэкапе)
│   └── matrix_backup_YYYYMMDD_HHMMSS.tar.gz
│
├── 📋 .gitignore                  # Игнорируемые файлы
└── 📜 LICENSE                     # MIT License

```

## Поток работы

### 1. Установка
```
install.sh
    │
    ├── Проверка ОС (Ubuntu 22.04/24.04)
    ├── Загрузка .env конфигурации
    ├── Валидация параметров
    │
    ├── Установка зависимостей
    │   ├── Docker
    │   └── Docker Compose
    │
    ├── Настройка Nginx
    │   └── Подстановка домена
    │
    ├── Запуск служб
    │   ├── PostgreSQL (ждем готовности)
    │   ├── Synapse (генерация конфига)
    │   └── Nginx
    │
    ├── Получение SSL
    │   ├── Let's Encrypt
    │   └── Включение HTTPS
    │
    └── Создание admin пользователя
```

### 2. Ежедневное использование
```
Создание пользователя → create-user.sh
Проверка статуса     → status.sh
Просмотр логов       → docker-compose logs -f
Бэкап                → backup.sh
Обновление           → update.sh
```

### 3. Восстановление
```
restore.sh
    │
    ├── Выбор бэкапа
    ├── Остановка служб
    ├── Восстановление PostgreSQL
    ├── Восстановление данных Synapse
    └── Запуск служб
```

## Порты

| Порт | Служба | Описание |
|------|---------|----------|
| 80   | Nginx   | HTTP (ACME challenge + redirect) |
| 443  | Nginx   | HTTPS (основной доступ) |
| 8008 | Synapse | Internal (не открыт наружу) |
| 8448 | Nginx   | Matrix Federation |

## Переменные окружения

| Переменная | Обязательная | Описание |
|------------|--------------|----------|
| `DOMAIN` | ✅ | Домен сервера (matrix.example.com) |
| `POSTGRES_PASSWORD` | ✅ | Пароль PostgreSQL |
| `SSL_EMAIL` | ✅ | Email для Let's Encrypt |
| `ADMIN_USERNAME` | ❌ | Логин администратора |
| `ADMIN_PASSWORD` | ❌ | Пароль администратора |
| `POSTGRES_USER` | ❌ | Пользователь БД (по умолчанию: synapse) |
| `POSTGRES_DB` | ❌ | Имя БД (по умолчанию: synapse) |
| `SYNAPSE_REPORT_STATS` | ❌ | Отправка статистики (по умолчанию: no) |

## Зависимости

### Системные
- Ubuntu 22.04 или 24.04
- 2+ GB RAM
- 20+ GB диск

### Docker образы
- `postgres:15-alpine` - База данных
- `matrixdotorg/synapse:latest` - Matrix сервер
- `nginx:alpine` - Reverse proxy
- `certbot/certbot` - SSL сертификаты

## Файлы данных

### Критически важные (нужны в бэкапе)
- PostgreSQL database
- `/data/homeserver.yaml` (конфиг Synapse)
- `/data/media_store/` (загруженные файлы)
- `/data/keys/` (ключи шифрования)
- SSL сертификаты

### Можно пересоздать
- Docker контейнеры
- Nginx конфиги
- `.env` (есть в бэкапе, но можно восстановить вручную)

## Безопасность

### Защищенные файлы
```
.env (chmod 600) - пароли и секреты
certbot/conf/    - приватные ключи SSL
```

### Открытые порты
```
22   - SSH (настройте firewall)
80   - HTTP
443  - HTTPS
8448 - Federation
```

### Не коммитить в Git
```
.env              - содержит пароли
certbot/          - SSL ключи
backups/          - может содержать конфиденциальные данные
postgres_data/    - база данных
synapse_data/     - пользовательские данные
```

---

**Документация актуальна на:** 2026-10-20
