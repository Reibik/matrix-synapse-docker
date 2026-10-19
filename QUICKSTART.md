# Matrix Synapse - Quick Setup Guide

## 🚀 Быстрый старт за 5 минут

### Шаг 1: Подготовка

Требования:
- Ubuntu 22.04 или 24.04
- 2 GB RAM минимум (4 GB рекомендуется)
- Доменное имя с настроенными DNS записями

### Шаг 2: Клонируйте репозиторий

```bash
git clone https://github.com/YOUR_USERNAME/matrix-synapse-docker.git
cd matrix-synapse-docker
```

### Шаг 3: Настройте конфигурацию

```bash
cp .env.example .env
nano .env
```

Измените эти строки:
```env
DOMAIN=matrix.yourdomain.com          # Ваш домен
POSTGRES_PASSWORD=strong_password_123  # Надежный пароль
SSL_EMAIL=admin@yourdomain.com        # Ваш email
ADMIN_USERNAME=admin                   # Логин администратора
ADMIN_PASSWORD=admin_password_456      # Пароль администратора
```

### Шаг 4: Настройте DNS

Создайте A-запись:
```
matrix.yourdomain.com  →  IP_ВАШЕГО_СЕРВЕРА
```

### Шаг 5: Запустите установку

```bash
sudo ./install.sh
```

✨ Готово! Через 5-10 минут ваш Matrix сервер будет работать.

## 📱 Подключение

1. Откройте https://app.element.io
2. Нажмите "Sign In"
3. Выберите "Edit" возле домашнего сервера
4. Введите: `matrix.yourdomain.com`
5. Войдите: `@admin:matrix.yourdomain.com`

## 🛠️ Полезные команды

```bash
# Создать пользователя
./scripts/create-user.sh

# Проверить статус
./scripts/status.sh

# Просмотр логов
docker-compose logs -f

# Бэкап
./scripts/backup.sh

# Остановить/запустить
docker-compose stop
docker-compose start
```

## 📚 Документация

Полная документация в [README.md](README.md)

## 🐛 Проблемы?

1. Проверьте логи: `docker-compose logs -f synapse`
2. Проверьте статус: `./scripts/status.sh`
3. Создайте Issue на GitHub

---

**Время установки:** ~5-10 минут  
**Сложность:** Легко 🟢
