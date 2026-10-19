# Часто задаваемые вопросы (FAQ)

## Общие вопросы

### Что такое Matrix?
Matrix - это открытый стандарт для децентрализованной коммуникации. Synapse - это reference-реализация сервера Matrix на Python.

### Зачем мне собственный Matrix сервер?
- Полный контроль над своими данными
- Приватность и безопасность
- Возможность кастомизации
- Независимость от сторонних сервисов
- Федерация с другими серверами

### Сколько стоит VPS?
Для небольшого сервера (до 10 пользователей):
- 5-10$ в месяц за VPS с 2-4 GB RAM
- Провайдеры: DigitalOcean, Hetzner, Vultr, Linode

### Нужно ли мне знать Linux?
Базовые знания полезны, но скрипт автоматизирует большую часть работы. Нужно уметь:
- Подключаться по SSH
- Копировать и редактировать файлы
- Запускать команды в терминале

## Установка и настройка

### Скрипт не запускается
Проверьте:
```bash
# Убедитесь, что скрипт исполняемый
chmod +x install.sh

# Запускайте с sudo
sudo ./install.sh

# Проверьте права на файл .env
ls -la .env
```

### SSL сертификат не получается
Причины:
1. **DNS не настроен** - проверьте: `dig yourdomain.com`
2. **Порты закрыты** - откройте 80 и 443 в firewall
3. **Домен не указывает на сервер** - IP должен совпадать
4. **Let's Encrypt rate limit** - подождите 1 час и попробуйте снова

Решение:
```bash
# Проверьте DNS
dig matrix.yourdomain.com

# Проверьте порты
sudo ufw allow 80
sudo ufw allow 443

# Попробуйте снова
./scripts/setup-ssl.sh
```

### Домен не резолвится
Подождите 10-60 минут после настройки DNS - изменения распространяются не сразу.

Проверьте:
```bash
# Локально
dig matrix.yourdomain.com

# Через публичный DNS
dig @8.8.8.8 matrix.yourdomain.com
```

### Ошибка "Cannot connect to Docker daemon"
```bash
# Проверьте статус Docker
sudo systemctl status docker

# Запустите Docker
sudo systemctl start docker

# Добавьте пользователя в группу docker
sudo usermod -aG docker $USER

# Перелогиньтесь
```

## Использование

### Как создать пользователя?
```bash
# Интерактивно
./scripts/create-user.sh

# Или напрямую
docker-compose exec synapse register_new_matrix_user \
    -u username -p password -c /data/homeserver.yaml \
    http://localhost:8008
```

### Как сбросить пароль пользователя?
```bash
docker-compose exec -T postgres psql -U synapse << EOF
UPDATE users SET password_hash = 'hashed_password' 
WHERE name = '@username:yourdomain.com';
EOF
```

Лучше создать нового пользователя и удалить старого.

### Как удалить пользователя?
```bash
# Деактивировать через API
curl -X POST \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"erase": true}' \
  "https://matrix.yourdomain.com/_synapse/admin/v1/deactivate/@username:yourdomain.com"
```

### Как изменить домен сервера?
**Внимание!** Это сложная операция. Домен Matrix сервера - это его идентификатор в сети, и его нельзя просто изменить.

Варианты:
1. Установить новый сервер с новым доменом
2. Использовать делегирование (advanced)

### Можно ли использовать поддомен?
Да! Например: `matrix.example.com` или `chat.example.com`

## Производительность

### Сервер тормозит
Причины и решения:

1. **Нехватка RAM**
```bash
# Проверьте использование
free -h
docker stats

# Добавьте swap
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

2. **Много федерированных комнат**
Отключите федерацию для приватного использования:
```yaml
# В homeserver.yaml
federation_domain_whitelist: []
```

3. **База данных переполнена**
```bash
# Очистите старые данные
docker-compose exec synapse synapse_auto_compressor
```

### Как узнать размер базы данных?
```bash
docker-compose exec postgres psql -U synapse -d synapse -c \
  "SELECT pg_size_pretty(pg_database_size('synapse'));"
```

### Высокая нагрузка на диск
SSD обязателен для нормальной работы Matrix. Если используете HDD - это проблема.

## Безопасность

### Нужен ли firewall?
Да! Настройте UFW:
```bash
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 8448/tcp  # Federation
sudo ufw enable
```

### Как отключить регистрацию?
В `homeserver.yaml`:
```yaml
enable_registration: false
```

Затем перезапустите:
```bash
docker-compose restart synapse
```

### Как включить регистрацию только по инвайтам?
```yaml
enable_registration: true
registration_requires_token: true
```

### Безопасны ли пароли в .env?
.env файл должен быть защищен:
```bash
# Установите правильные права
chmod 600 .env

# Убедитесь, что он в .gitignore
cat .gitignore | grep .env
```

## Обслуживание

### Как делать бэкапы?
```bash
# Создать бэкап
./scripts/backup.sh

# Автоматический бэкап каждый день в 3 AM
echo "0 3 * * * cd /path/to/matrix && ./scripts/backup.sh" | crontab -
```

### Как восстановить из бэкапа?
```bash
./scripts/restore.sh
```

**Внимание:** Это перезапишет все текущие данные!

### Как обновить Synapse?
```bash
# Сделайте бэкап
./scripts/backup.sh

# Обновите
docker-compose pull synapse
docker-compose up -d synapse

# Проверьте логи
docker-compose logs -f synapse
```

### Как посмотреть логи?
```bash
# Все сервисы
docker-compose logs -f

# Только Synapse
docker-compose logs -f synapse

# Последние 100 строк
docker-compose logs --tail=100 synapse

# С временными метками
docker-compose logs -f --timestamps synapse
```

### Где хранятся данные?
- **PostgreSQL база:** Docker volume `postgres_data`
- **Synapse данные:** Docker volume `synapse_data` (медиа, ключи, конфиг)
- **SSL сертификаты:** `./certbot/conf/`
- **Бэкапы:** `./backups/`

### Как полностью удалить все?
```bash
# Остановить и удалить контейнеры
docker-compose down

# Удалить volumes (ВНИМАНИЕ: удалит все данные!)
docker-compose down -v

# Удалить certbot данные
rm -rf certbot/

# Удалить бэкапы
rm -rf backups/
```

## Федерация

### Что такое федерация?
Федерация позволяет вашему серверу общаться с другими Matrix серверами (как email между разными провайдерами).

### Нужна ли мне федерация?
- **Да** - если хотите общаться с пользователями других серверов
- **Нет** - если сервер только для вашей команды/организации

### Как отключить федерацию?
В `homeserver.yaml`:
```yaml
federation_domain_whitelist: []
```

### Порт 8448 обязателен?
Для федерации - да. Если федерация не нужна, можно закрыть.

## Интеграции

### Как подключить бота?
1. Создайте пользователя для бота
2. Получите access token
3. Используйте Matrix SDK для вашего языка программирования

### Можно ли подключить Telegram/Discord мост?
Да! Существуют мосты:
- **mautrix-telegram** - для Telegram
- **mx-puppet-discord** - для Discord
- **matrix-appservice-irc** - для IRC

Но это требует дополнительной настройки.

### Как подключить Element Web к своему серверу?
Element Web уже может подключаться к любому серверу. При входе просто укажите ваш домен.

Для самостоятельного хостинга Element Web добавьте его в docker-compose.yml.

## Устранение проблем

### "Internal Server Error" при регистрации
Проверьте логи:
```bash
docker-compose logs synapse | grep ERROR
```

Часто это проблемы с:
- PostgreSQL подключением
- Правами доступа к файлам
- Конфигурацией homeserver.yaml

### Пользователи не могут войти
1. Проверьте, что Synapse работает: `./scripts/status.sh`
2. Проверьте логи: `docker-compose logs synapse`
3. Проверьте, что пользователь существует
4. Проверьте SSL сертификат

### "Unable to verify" ключи шифрования
Это нормально при первом входе с нового устройства. Нужно:
1. Подтвердить устройство с другого устройства
2. Или ввести recovery key
3. Или начать новую сессию (потеряется история зашифрованных сообщений)

### Медленная синхронизация
1. Проверьте нагрузку: `htop`
2. Проверьте диск: `df -h`
3. Проверьте логи на ошибки
4. Возможно нужно больше RAM

## Миграция

### Как перенести сервер на новый VPS?
1. Сделайте бэкап: `./scripts/backup.sh`
2. Скопируйте бэкап на новый сервер
3. Установите Matrix на новом сервере
4. Восстановите бэкап: `./scripts/restore.sh`
5. Перенаправьте DNS на новый IP

### Как перенести данные с другой установки?
Если у вас Synapse на другой платформе:
1. Сделайте дамп PostgreSQL базы
2. Скопируйте медиа файлы
3. Импортируйте в новую установку

## Дополнительно

### Где найти помощь?
- GitHub Issues этого проекта
- [Matrix.org Community](https://matrix.to/#/#synapse:matrix.org)
- [Synapse Admin Guide](https://matrix-org.github.io/synapse/latest/)

### Как внести вклад в проект?
Pull requests приветствуются! Форкните репозиторий и создайте PR.

### Где документация Matrix API?
https://spec.matrix.org/latest/

---

**Не нашли ответ?** Создайте Issue на GitHub!
