# Matrix Synapse - Docker Setup

Автоматическая установка Matrix Synapse с использованием Docker Compose для Ubuntu 22.04/24.04.

## Возможности

✨ **Полностью автоматическая установка** - один скрипт развернет весь сервер  
🔒 **Автоматический SSL** - Let's Encrypt сертификаты настраиваются автоматически  
🐳 **Docker-based** - легко обновлять и управлять  
🗄️ **PostgreSQL** - производительная база данных  
🌐 **Nginx reverse proxy** - с оптимизированной конфигурацией  
📦 **Готовые скрипты** - для создания пользователей, бэкапов и управления  

## Требования

- VPS с Ubuntu 22.04 или 24.04
- Минимум 2 GB RAM (рекомендуется 4 GB)
- 20 GB свободного места на диске
- Доменное имя с настроенными DNS записями
- Root доступ к серверу

## Быстрый старт

### 1. Клонируйте репозиторий

```bash
git clone https://github.com/YOUR_USERNAME/matrix-synapse-docker.git
cd matrix-synapse-docker
```

### 2. Настройте конфигурацию

```bash
cp .env.example .env
nano .env
```

Измените следующие параметры:

```env
# Ваш домен (обязательно)
DOMAIN=matrix.example.com

# Пароль для PostgreSQL (обязательно)
POSTGRES_PASSWORD=your_strong_password_here

# Email для SSL сертификата (обязательно)
SSL_EMAIL=admin@example.com

# Данные администратора
ADMIN_USERNAME=admin
ADMIN_PASSWORD=your_admin_password_here
```

### 3. Настройте DNS

Создайте A-запись для вашего домена, указывающую на IP адрес вашего сервера:

```
matrix.example.com  →  YOUR_SERVER_IP
```

Проверьте DNS перед установкой:
```bash
dig matrix.example.com
```

### 4. Запустите установку

```bash
sudo ./install.sh
```

Скрипт автоматически:
- Установит Docker и Docker Compose
- Настроит PostgreSQL
- Развернет Matrix Synapse
- Получит SSL сертификат
- Настроит nginx
- Создаст администратора

## Использование

### Подключение к серверу

После установки вы можете подключиться к своему серверу используя любой Matrix клиент:

**Element Web:** https://app.element.io
- Нажмите "Sign In"
- Выберите "Edit" возле "matrix.org"
- Введите ваш домен: `matrix.example.com`
- Войдите с логином: `@admin:matrix.example.com`

**Другие клиенты:**
- Element Desktop
- Element iOS/Android
- FluffyChat
- SchildiChat

### Управление пользователями

#### Создать нового пользователя

```bash
./scripts/create-user.sh
```

Скрипт запросит:
- Username
- Password
- Права администратора (y/N)

#### Создать пользователя через командную строку

```bash
docker-compose exec synapse register_new_matrix_user \
    -u username -p password -a -c /data/homeserver.yaml \
    http://localhost:8008
```

Флаг `-a` делает пользователя администратором.

### Бэкапы

#### Создать бэкап

```bash
./scripts/backup.sh
```

Бэкап будет сохранен в `./backups/` и включает:
- PostgreSQL базу данных
- Данные Synapse (медиа файлы, ключи шифрования)
- Конфигурационные файлы

#### Восстановить из бэкапа

```bash
./scripts/restore.sh
```

⚠️ **Внимание:** Это перезапишет текущие данные!

### Мониторинг

#### Проверить статус

```bash
./scripts/status.sh
```

#### Просмотр логов

```bash
# Все сервисы
docker-compose logs -f

# Конкретный сервис
docker-compose logs -f synapse
docker-compose logs -f postgres
docker-compose logs -f nginx
```

#### Проверить работающие контейнеры

```bash
docker-compose ps
```

### Управление сервисами

```bash
# Остановить все сервисы
docker-compose stop

# Запустить все сервисы
docker-compose start

# Перезапустить все сервисы
docker-compose restart

# Перезапустить конкретный сервис
docker-compose restart synapse

# Остановить и удалить контейнеры (данные сохраняются)
docker-compose down

# Остановить и удалить контейнеры и данные
docker-compose down -v
```

## Обновление

### Обновить Matrix Synapse

```bash
# Создайте бэкап перед обновлением
./scripts/backup.sh

# Обновите образ и перезапустите
docker-compose pull synapse
docker-compose up -d synapse
```

### Обновить все компоненты

```bash
docker-compose pull
docker-compose up -d
```

## Безопасность

### Firewall

Настройте UFW для защиты сервера:

```bash
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 8448/tcp  # Matrix Federation
sudo ufw enable
```

### SSL сертификаты

Сертификаты автоматически обновляются каждые 12 часов через certbot.

Вручную обновить сертификат:
```bash
docker-compose run --rm certbot renew
docker-compose restart nginx
```

### Безопасные пароли

- Используйте сложные пароли для `POSTGRES_PASSWORD`
- Используйте сложные пароли для всех пользователей
- Храните `.env` файл в безопасности
- Не коммитьте `.env` в git

## Расширенная конфигурация

### Изменить конфигурацию Synapse

Конфигурация хранится в Docker volume. Чтобы её изменить:

```bash
# Найти volume
docker volume ls | grep synapse

# Отредактировать homeserver.yaml
docker-compose exec synapse nano /data/homeserver.yaml

# Перезапустить после изменений
docker-compose restart synapse
```

### Настроить лимиты

В `homeserver.yaml` можно настроить:
- Максимальный размер файлов
- Лимиты регистрации
- Настройки федерации
- И многое другое

### Добавить Element Web

Добавьте в `docker-compose.yml`:

```yaml
  element:
    image: vectorim/element-web:latest
    container_name: element-web
    restart: unless-stopped
    volumes:
      - ./element-config.json:/app/config.json
    ports:
      - "8080:80"
```

## Устранение неполадок

### Проблемы с SSL

Если SSL сертификат не получен:

```bash
# Проверьте DNS
dig your-domain.com

# Проверьте, что порты открыты
sudo netstat -tulpn | grep -E ':(80|443)'

# Попробуйте снова
./scripts/setup-ssl.sh
```

### Synapse не запускается

```bash
# Проверьте логи
docker-compose logs synapse

# Проверьте конфигурацию
docker-compose exec synapse python -m synapse.config --generate-config \
    --config-path=/data/homeserver.yaml --report-stats=no
```

### PostgreSQL проблемы

```bash
# Проверьте подключение
docker-compose exec postgres psql -U synapse -d synapse -c "SELECT version();"

# Проверьте размер базы
docker-compose exec postgres psql -U synapse -d synapse -c "SELECT pg_size_pretty(pg_database_size('synapse'));"
```

### Нехватка памяти

Если сервер тормозит:

1. Увеличьте RAM на VPS
2. Настройте swap:
```bash
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

## Структура проекта

```
matrix-synapse-docker/
├── docker-compose.yml       # Основная конфигурация Docker
├── .env.example            # Шаблон переменных окружения
├── install.sh              # Главный установочный скрипт
├── README.md              # Документация
├── nginx/
│   ├── nginx.conf         # Конфигурация nginx
│   └── matrix.conf        # Конфигурация для Matrix
├── scripts/
│   ├── create-user.sh     # Создание пользователей
│   ├── backup.sh          # Бэкап данных
│   ├── restore.sh         # Восстановление из бэкапа
│   ├── status.sh          # Проверка статуса
│   └── setup-ssl.sh       # Настройка SSL
└── certbot/               # SSL сертификаты (создается при установке)
```

## Требования к серверу по нагрузке

| Пользователи | CPU | RAM | Диск |
|-------------|-----|-----|------|
| 1-10 | 1-2 ядра | 2-4 GB | 20-40 GB |
| 10-100 | 2-4 ядра | 4-8 GB | 50-100 GB |
| 100-500 | 4-8 ядер | 8-16 GB | 100-500 GB |
| 500+ | 8+ ядер | 16+ GB | 500+ GB |

## Полезные ссылки

- [Matrix.org](https://matrix.org) - Официальный сайт
- [Synapse Documentation](https://matrix-org.github.io/synapse/latest/) - Документация Synapse
- [Element](https://element.io) - Рекомендуемый клиент
- [Matrix Spec](https://spec.matrix.org) - Спецификация протокола

## Лицензия

MIT License

## Поддержка

Если у вас возникли проблемы:
1. Проверьте [Issues](https://github.com/YOUR_USERNAME/matrix-synapse-docker/issues)
2. Создайте новый Issue с описанием проблемы
3. Приложите вывод `./scripts/status.sh` и логи

## Вклад в проект

Pull requests приветствуются! Для значительных изменений сначала откройте Issue для обсуждения.

---

**Сделано с ❤️ для сообщества Matrix**
