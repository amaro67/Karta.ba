# 🐳 Docker Quick Start Guide - Karta.ba

Ovaj vodič objašnjava kako brzo pokrenuti Karta.ba aplikaciju sa Docker-om.

## 📋 Preduslovi

- Docker Desktop instaliran i pokrenut
- Minimum 4GB RAM dostupno za Docker

## 🚀 Brzo pokretanje (Development)

```bash
# 1. Klonirajte repository (ako već niste)
cd Karta.ba

# 2. Pokrenite sve servise
docker-compose up --build

# Aplikacija će biti dostupna na:
# - API: http://localhost:8080
# - Swagger: http://localhost:8080/swagger
# - RabbitMQ Management: http://localhost:15672 (guest/guest)
```

## 📦 Šta se pokreće?

Docker Compose automatski pokreće 3 servisa:

1. **karta-api** - .NET 8 Web API aplikacija
2. **sqlserver** - SQL Server baza podataka
3. **rabbitmq** - RabbitMQ message broker

## ⚙️ Konfiguracija

### Environment varijable

Za prilagođavanje konfiguracije, kreirajte `.env` fajl:

```bash
cp env.example .env
# Editujte .env fajl sa vašim vrednostima
```

### Važne environment varijable

- `EMAIL_USE_RABBITMQ` - Postavite na `true` da koristite RabbitMQ za email-ove
- `RABBITMQ_USERNAME` - RabbitMQ korisničko ime (default: guest)
- `RABBITMQ_PASSWORD` - RabbitMQ lozinka (default: guest)
- `SQL_SA_PASSWORD` - SQL Server SA lozinka (za production)

## 🎯 Osnovne komande

```bash
# Pokretanje u pozadini
docker-compose up -d

# Zaustavljanje
docker-compose down

# Pregled logova
docker-compose logs -f

# Restart servisa
docker-compose restart karta-api

# Pregled statusa
docker-compose ps
```

## 🔍 Provera da li sve radi

```bash
# 1. Proverite da li su svi servisi pokrenuti
docker-compose ps

# 2. Testirajte API
curl http://localhost:8080/

# 3. Otvorite Swagger UI
open http://localhost:8080/swagger

# 4. Otvorite RabbitMQ Management
open http://localhost:15672
# Login: guest / guest
```

## 🐛 Troubleshooting

### Port je zauzet

```bash
# Proverite koji proces koristi port
lsof -i :8080  # za API
lsof -i :1433  # za SQL Server
lsof -i :5672  # za RabbitMQ

# Promenite port u docker-compose.yml ako je potrebno
```

### Servisi se ne pokreću

```bash
# Proverite logove
docker-compose logs karta-api
docker-compose logs sqlserver
docker-compose logs rabbitmq

# Rebuild sve
docker-compose down
docker-compose build --no-cache
docker-compose up
```

### Baza podataka se ne kreira

```bash
# Proverite SQL Server logove
docker-compose logs sqlserver

# Proverite da li je SQL Server spreman
docker-compose exec sqlserver /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "KartaPassword2024!" -Q "SELECT 1"
```

## 📚 Dodatne informacije

Za detaljnije informacije, pogledajte:
- [DOCKER_README.md](./DOCKER_README.md) - Detaljna dokumentacija
- [DATABASE_DOCKER_SETUP.md](./DATABASE_DOCKER_SETUP.md) - Informacije o bazi podataka
- [RABBITMQ_SETUP.md](./RABBITMQ_SETUP.md) - Informacije o RabbitMQ

## 🔐 Production

Za production okruženje:

```bash
# 1. Kreirajte .env fajl sa production vrednostima
cp env.example .env
# Editujte .env sa production vrednostima

# 2. Pokrenite production verziju
docker-compose -f docker-compose.yml -f docker-compose.production.yml up -d

# 3. Proverite logove
docker-compose -f docker-compose.yml -f docker-compose.production.yml logs -f
```

**VAŽNO za production:**
- Promenite sve default lozinke
- Koristite jak JWT_SECRET_KEY
- Ograničite CORS origins
- Koristite HTTPS

