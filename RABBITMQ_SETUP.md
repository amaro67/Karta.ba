# 🐰 RabbitMQ Setup za Karta.ba

## Instalacija RabbitMQ

### Docker (Preporučeno)
```bash
# Pokreni RabbitMQ u Docker-u
docker run -d --name rabbitmq -p 5672:5672 -p 15672:15672 rabbitmq:3-management

# Pristup web interfejsu: http://localhost:15672
# Username: guest, Password: guest
```

### macOS (Homebrew)
```bash
brew install rabbitmq
brew services start rabbitmq
```

### Linux (Ubuntu/Debian)
```bash
sudo apt-get install rabbitmq-server
sudo systemctl start rabbitmq-server
sudo systemctl enable rabbitmq-server
```

## Konfiguracija

### Trenutno stanje (SMTP)
```bash
# U .env fajlu ili environment varijablama
EMAIL_USE_RABBITMQ=false
```

### Aktivacija RabbitMQ
```bash
# U .env fajlu ili environment varijablama
EMAIL_USE_RABBITMQ=true
```

## Testiranje

### Test 1: SMTP mod (trenutno aktivan)
```bash
curl -X POST "https://localhost:7000/api/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test-smtp@example.com",
    "password": "Test123!@#",
    "firstName": "Test",
    "lastName": "SMTP"
  }'
```

### Test 2: RabbitMQ mod
```bash
# Postavi EMAIL_USE_RABBITMQ=true
export EMAIL_USE_RABBITMQ=true

curl -X POST "https://localhost:7000/api/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test-rabbitmq@example.com",
    "password": "Test123!@#",
    "firstName": "Test",
    "lastName": "RabbitMQ"
  }'
```

## Monitoring

### RabbitMQ Management UI
- Otvori: http://localhost:15672
- Username: guest, Password: guest
- Provjeri queue: `email_queue`

### Logovi
```bash
# Pratite logove
tail -f logs/karta-.log | grep -i "email\|rabbitmq"
```

## Kako funkcionira

### SMTP mod (EMAIL_USE_RABBITMQ=false)
1. Registracija → direktno slanje email-a kroz SMTP
2. HTTP zahtjev čeka dok se email pošalje (2-3 sekunde)
3. Ako SMTP ne radi, registracija neće raditi

### RabbitMQ mod (EMAIL_USE_RABBITMQ=true)
1. Registracija → email se stavlja u queue
2. HTTP zahtjev se završava odmah (< 200ms)
3. Background servis obrađuje email-e iz queue-a
4. Automatski fallback na SMTP ako RabbitMQ nije dostupan

## Prednosti RabbitMQ

- ✅ **Brži odgovor** - HTTP zahtjev se završava odmah
- ✅ **Pouzdanost** - email se čuva u queue-u dok se ne pošalje
- ✅ **Retry logika** - automatski pokušava ponovo
- ✅ **Skaliranje** - možeš imati više worker-a
- ✅ **Monitoring** - vidiš koliko emailova čeka

## Automatski Fallback

Aplikacija automatski koristi SMTP ako:
- `EMAIL_USE_RABBITMQ=false`
- RabbitMQ nije dostupan
- RabbitMQ servis nije konfigurisan

## Frontend

**Nema promjena u frontend kodu!** API endpoint i response ostaju identični.

## Produkcija

Za produkciju:
1. Postavi `EMAIL_USE_RABBITMQ=true`
2. Konfiguriraj RabbitMQ server
3. Postavi environment varijable za RabbitMQ
4. Monitoriraj queue kroz RabbitMQ Management UI
