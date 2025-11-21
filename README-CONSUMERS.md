# Gestion des Consumers RabbitMQ dans le Dockerfile

Cette image Docker intègre **supervisor** pour gérer automatiquement PHP-FPM et les consumers RabbitMQ Symfony.

## Utilisation de base

Par défaut, l'image lance **uniquement PHP-FPM** :

```bash
docker build -t mon-app .
docker run -d mon-app
```

## Activer les consumers

Utilisez des **variables d'environnement** pour activer les consumers :

```bash
docker run -d \
  -e START_CONSUMER_EMAIL=1 \
  -e START_CONSUMER_NOTIFICATION=1 \
  -e START_CONSUMER_PDF=1 \
  mon-app
```

## Variables d'environnement disponibles

### Activation des consumers

- `START_CONSUMER_EMAIL=1` - Active le consumer email
- `START_CONSUMER_NOTIFICATION=1` - Active le consumer notification  
- `START_CONSUMER_PDF=1` - Active le consumer PDF
- `CONSUMER_CUSTOM_TRANSPORT=mon_transport` - Consumer générique avec transport personnalisé

### Configuration par consumer

Pour chaque consumer, vous pouvez personnaliser :

**Email :**
- `CONSUMER_EMAIL_TRANSPORT=async_email` (défaut: `async_email`)
- `CONSUMER_EMAIL_TIME_LIMIT=3600` (défaut: `3600` secondes)
- `CONSUMER_EMAIL_MEMORY_LIMIT=128M` (défaut: `128M`)

**Notification :**
- `CONSUMER_NOTIFICATION_TRANSPORT=async_notification` (défaut: `async_notification`)
- `CONSUMER_NOTIFICATION_TIME_LIMIT=3600` (défaut: `3600`)
- `CONSUMER_NOTIFICATION_MEMORY_LIMIT=128M` (défaut: `128M`)

**PDF :**
- `CONSUMER_PDF_TRANSPORT=async_pdf` (défaut: `async_pdf`)
- `CONSUMER_PDF_TIME_LIMIT=3600` (défaut: `3600`)
- `CONSUMER_PDF_MEMORY_LIMIT=256M` (défaut: `256M`)

**Custom :**
- `CONSUMER_CUSTOM_TRANSPORT=mon_transport` (requis)
- `CONSUMER_CUSTOM_TIME_LIMIT=3600` (défaut: `3600`)
- `CONSUMER_CUSTOM_MEMORY_LIMIT=128M` (défaut: `128M`)

## Exemples d'utilisation

### Exemple 1 : PHP-FPM + Consumer Email uniquement

```bash
docker run -d \
  -v $(pwd):/var/www \
  -e START_CONSUMER_EMAIL=1 \
  -e CONSUMER_EMAIL_TRANSPORT=async_email \
  mon-app
```

### Exemple 2 : Tous les consumers avec configuration personnalisée

```bash
docker run -d \
  -v $(pwd):/var/www \
  -e START_CONSUMER_EMAIL=1 \
  -e CONSUMER_EMAIL_MEMORY_LIMIT=256M \
  -e START_CONSUMER_NOTIFICATION=1 \
  -e CONSUMER_NOTIFICATION_TIME_LIMIT=7200 \
  -e START_CONSUMER_PDF=1 \
  mon-app
```

### Exemple 3 : Consumer personnalisé

```bash
docker run -d \
  -v $(pwd):/var/www \
  -e CONSUMER_CUSTOM_TRANSPORT=async_import \
  -e CONSUMER_CUSTOM_MEMORY_LIMIT=512M \
  mon-app
```

### Exemple 4 : Lancer uniquement PHP-FPM (sans consumers)

```bash
docker run -d mon-app php-fpm -F
```

### Exemple 5 : Lancer uniquement un consumer spécifique (sans supervisor)

```bash
docker run -d mon-app php bin/console messenger:consume async_email -vv
```

## Gestion avec supervisor

Une fois le conteneur lancé, vous pouvez interagir avec supervisor :

```bash
# Voir le statut de tous les processus
docker exec <container_id> supervisorctl status

# Redémarrer un consumer
docker exec <container_id> supervisorctl restart consumer-email

# Arrêter un consumer
docker exec <container_id> supervisorctl stop consumer-email

# Démarrer un consumer
docker exec <container_id> supervisorctl start consumer-email

# Voir les logs d'un consumer
docker exec <container_id> supervisorctl tail -f consumer-email

# Recharger la configuration
docker exec <container_id> supervisorctl reread
docker exec <container_id> supervisorctl update
```

## Logs

Les logs sont disponibles dans `/var/log/supervisor/` :

- `supervisord.log` - Logs de supervisor
- `php-fpm.out.log` / `php-fpm.err.log` - Logs PHP-FPM
- `consumer-pdf.out.log` / `consumer-pdf.err.log` - Logs consumer PDF

Pour voir les logs en temps réel :

```bash
docker exec <container_id> tail -f /var/log/supervisor/consumer-email.out.log
```

## Docker Compose (optionnel)

Si vous utilisez docker-compose, voici un exemple :

```yaml
version: '3.8'
services:
  app:
    build: .
    environment:
      - START_CONSUMER_EMAIL=1
      - START_CONSUMER_NOTIFICATION=1
      - CONSUMER_EMAIL_MEMORY_LIMIT=256M
    volumes:
      - .:/var/www
```

## Notes importantes

1. **Par défaut**, seul PHP-FPM démarre. Les consumers doivent être activés explicitement.

2. **Les consumers redémarrent automatiquement** en cas de crash grâce à supervisor.

3. **Les limites mémoire et temps** sont importantes pour éviter les fuites mémoire. Ajustez selon vos besoins.

4. **Les noms de transports** (`async_email`, `async_notification`, etc.) doivent correspondre à votre configuration Symfony `messenger.yaml`.

5. Pour **scalabilité horizontale**, lancez plusieurs conteneurs avec les mêmes consumers activés.
