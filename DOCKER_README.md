# Docker Deployment za Karta.ba

Ovaj dokument objašnjava kako da pokrenete Karta.ba aplikaciju koristeći Docker.

## Preduslovi

- Docker Desktop instaliran na vašem sistemu
- Docker Compose (dolazi sa Docker Desktop)

## Brzo pokretanje

### 1. Development okruženje

```bash
# Klonirajte repository i idite u direktorijum
cd Karta

# Pokrenite aplikaciju
docker-compose up --build
```

Aplikacija će biti dostupna na: http://localhost:8080
Swagger dokumentacija: http://localhost:8080/swagger

### 2. Production okruženje

```bash
# Kreirajte .env fajl sa production vrednostima
cp env.example .env
# Editujte .env fajl sa vašim production vrednostima

# Pokrenite production verziju
docker-compose -f docker-compose.yml -f docker-compose.production.yml up --build -d
```

## Konfiguracija

### Environment varijable

Kreirajte `.env` fajl na osnovu `env.example`:

```bash
cp env.example .env
```

**VAŽNO**: Promenite sledeće vrednosti za production:

- `JWT_SECRET_KEY` - generišite sigurni ključ
- `STRIPE_SECRET_KEY` - vaš production Stripe ključ
- `EMAIL_SMTP_PASSWORD` - vaš email app password
- `CORS_ALLOWED_ORIGINS` - vaši domeni

### Volumes

Aplikacija koristi sledeće volume mount-ove:

- `./data:/app/data` - SQLite baza podataka
- `./logs:/app/logs` - log fajlovi

## Komande

### Osnovne komande

```bash
# Pokretanje aplikacije
docker-compose up

# Pokretanje u pozadini
docker-compose up -d

# Zaustavljanje aplikacije
docker-compose down

# Rebuild i pokretanje
docker-compose up --build

# Pregled logova
docker-compose logs -f karta-api
```

### Development komande

```bash
# Pokretanje samo API-ja (bez RabbitMQ)
docker-compose up karta-api

# Pokretanje sa RabbitMQ
docker-compose --profile rabbitmq up

# Pregled statusa servisa
docker-compose ps

# Restart aplikacije
docker-compose restart karta-api
```

### Production komande

```bash
# Pokretanje production verzije
docker-compose -f docker-compose.yml -f docker-compose.production.yml up -d

# Zaustavljanje production verzije
docker-compose -f docker-compose.yml -f docker-compose.production.yml down

# Pregled production logova
docker-compose -f docker-compose.yml -f docker-compose.production.yml logs -f karta-api
```

## Troubleshooting

### Česti problemi

1. **Port 8080 je zauzet**
   ```bash
   # Promenite port u docker-compose.yml
   ports:
     - "8081:8080"  # Koristite port 8081 umesto 8080
   ```

2. **Baza podataka se ne kreira**
   ```bash
   # Kreirajte data direktorijum
   mkdir -p data
   chmod 755 data
   ```

3. **Permission denied za log fajlove**
   ```bash
   # Kreirajte logs direktorijum
   mkdir -p logs
   chmod 755 logs
   ```

4. **Aplikacija se ne pokreće**
   ```bash
   # Proverite logove
   docker-compose logs karta-api
   
   # Proverite da li je image kreiran
   docker images | grep karta
   ```

### Debugging

```bash
# Ulazak u kontejner
docker-compose exec karta-api bash

# Pregled procesa u kontejneru
docker-compose exec karta-api ps aux

# Pregled environment varijabli
docker-compose exec karta-api env
```

## Monitoring

### Health Check

Aplikacija ima built-in health check na `/` endpoint-u.

```bash
# Test health check-a
curl http://localhost:8080/

# Ili u browser-u
http://localhost:8080/
```

### Logovi

Logovi se čuvaju u `./logs` direktorijumu i mogu se pristupiti kroz:

```bash
# Real-time logovi
docker-compose logs -f karta-api

# Poslednji 100 linija
docker-compose logs --tail=100 karta-api
```

## Backup i Restore

### Backup baze podataka

```bash
# Kopirajte SQLite fajl
cp data/KartaDb.db backup/KartaDb_$(date +%Y%m%d_%H%M%S).db
```

### Restore baze podataka

```bash
# Zamenite SQLite fajl
cp backup/KartaDb_20240101_120000.db data/KartaDb.db
docker-compose restart karta-api
```

## Skaliranje

Za skaliranje aplikacije, možete pokrenuti više instanci:

```bash
# Pokretanje 3 instance
docker-compose up --scale karta-api=3
```

**Napomena**: Za skaliranje će vam trebati load balancer (nginx, traefik, itd.)

## Security

### Production sigurnost

1. **Promenite sve default vrednosti** u `.env` fajlu
2. **Koristite HTTPS** u production
3. **Ograničite CORS** origins na vaše domene
4. **Koristite sigurne JWT ključeve**
5. **Redovno ažurirajte Docker images**

### Firewall

```bash
# Otvorite samo potrebne portove
# 80 - HTTP
# 443 - HTTPS
# 8080 - samo za development
```

## Dodatni resursi

- [Docker dokumentacija](https://docs.docker.com/)
- [Docker Compose dokumentacija](https://docs.docker.com/compose/)
- [.NET Docker images](https://hub.docker.com/_/microsoft-dotnet)
