# Sigurnosna dokumentacija - Karta API

## Pregled sigurnosnih mjera

Ovaj dokument opisuje implementirane sigurnosne mjere u Karta API aplikaciji, uključujući autorizaciju, autentifikaciju i kontrolu pristupa.

## Autentifikacija

### JWT Token autentifikacija
- **Status**: ✅ Implementirano
- **Opis**: Korisnici se autentifikuju kroz JWT tokene
- **Endpointi**: 
  - `POST /api/Auth/register` - Registracija korisnika
  - `POST /api/Auth/login` - Prijava korisnika
  - `POST /api/Auth/refresh-token` - Obnavljanje tokena
  - `POST /api/Auth/forgot-password` - Zaboravljena lozinka
  - `POST /api/Auth/reset-password` - Resetovanje lozinke

### Email potvrda
- **Status**: ✅ Implementirano
- **Opis**: Korisnici moraju potvrditi email adresu nakon registracije
- **Konfiguracija**: Gmail SMTP server
- **Email adresa**: amar.omerovic0607@gmail.com

## Autorizacija i Role

### Implementirane role
1. **User (Kupac)**
   - Pregledava događaje
   - Kupuje karte
   - Upravlja svojim narudžbama

2. **Organizer (Organizator)**
   - Kreira i uređuje događaje
   - Upravlja cijenama i kapacitetima
   - Pregledava prodaju

3. **Scanner (Osoblje na ulazu)**
   - Skenira i validira karte
   - Ograničen pristup samo za validaciju

4. **Admin (Administrator)**
   - Puna kontrola nad sistemom
   - Upravlja korisnicima i rolama
   - Pregled svih podataka

## Kontrola pristupa po endpointima

### Event Controller (`/api/Event`)

#### Javni endpointi (bez autorizacije)
- `GET /api/Event` - Pregled svih događaja
- `GET /api/Event/{id}` - Pregled pojedinačnog događaja

#### Zaštićeni endpointi
- `POST /api/Event` - Kreiranje događaja
  - **Dozvola**: `CreateEvents`
  - **Dostupno**: Organizer, Admin

- `PUT /api/Event/{id}` - Ažuriranje događaja
  - **Dozvola**: `EditOwnEvents`
  - **Dostupno**: Organizer (samo svoje), Admin (sve)

- `DELETE /api/Event/{id}` - Brisanje događaja
  - **Dozvola**: `DeleteOwnEvents`
  - **Dostupno**: Organizer (samo svoje), Admin (sve)

- `POST /api/Event/{id}/archive` - Arhiviranje događaja
  - **Dozvola**: `EditOwnEvents`
  - **Dostupno**: Organizer (samo svoje), Admin (sve)

### Role Controller (`/api/Role`)

#### Javni endpointi (bez autorizacije)
- `GET /api/Role` - Pregled svih rola
- `GET /api/Role/{id}` - Pregled pojedinačne role
- `GET /api/Role/name/{name}` - Pregled role po nazivu

#### Zaštićeni endpointi (samo Admin)
- `POST /api/Role` - Kreiranje nove role
- `PUT /api/Role` - Ažuriranje role
- `DELETE /api/Role/{id}` - Brisanje role
- `POST /api/Role/users` - Dodavanje role korisniku
- `DELETE /api/Role/users` - Uklanjanje role od korisnika
- `GET /api/Role/users/{roleName}` - Pregled korisnika sa određenom rolom
- `GET /api/Role/user/{userId}` - Pregled rola korisnika
- `GET /api/Role/check/{userId}/{roleName}` - Provjera da li korisnik ima određenu rolu

### Auth Controller (`/api/Auth`)

#### Javni endpointi (bez autorizacije)
- `POST /api/Auth/register` - Registracija korisnika
- `POST /api/Auth/login` - Prijava korisnika
- `POST /api/Auth/forgot-password` - Zaboravljena lozinka
- `POST /api/Auth/reset-password` - Resetovanje lozinke

#### Zaštićeni endpointi
- `POST /api/Auth/refresh-token` - Obnavljanje tokena
  - **Dostupno**: Svi autentifikovani korisnici

- `POST /api/Auth/test-email` - Testiranje email servisa
  - **Dostupno**: Samo Admin

## Sigurnosne značajke

### Password Reset
- **Status**: ✅ Implementirano
- **Opis**: Sigurno resetovanje lozinke kroz email tokene
- **Karakteristike**:
  - Tokeni imaju rok trajanja (24 sata)
  - Jednokratna upotreba tokena
  - Automatsko invalidiranje starih tokena
  - Email potvrda o uspješnoj promjeni lozinke

### Globalno rukovanje greškama
- **Status**: ✅ Implementirano
- **Opis**: Centralizovano rukovanje greškama sa standardizovanim odgovorima
- **Tipovi grešaka**:
  - `BusinessException` - Poslovne greške
  - `NotFoundException` - Nije pronađeno
  - `ValidationException` - Validacijske greške
  - `UnauthorizedException` - Nije autorizovan
  - `ForbiddenException` - Nema dozvolu

### Logging
- **Status**: ✅ Implementirano
- **Opis**: Strukturirano logiranje sa Serilog
- **Lokacije logova**:
  - Console output
  - File: `logs/karta-dev-{date}.log`
  - Debug output

## Testiranje sigurnosti

### Testiranje javnih endpointa
```bash
# Pregled svih rola (treba raditi bez autorizacije)
curl -X GET "http://localhost:8080/api/Role"

# Pregled svih događaja (treba raditi bez autorizacije)
curl -X GET "http://localhost:8080/api/Event"
```

### Testiranje zaštićenih endpointa
```bash
# Kreiranje role (treba vratiti 401 Unauthorized)
curl -X POST "http://localhost:8080/api/Role" \
  -H "Content-Type: application/json" \
  -d '{"name":"TestRole","description":"Test role"}'

# Ažuriranje role (treba vratiti 401 Unauthorized)
curl -X PUT "http://localhost:8080/api/Role" \
  -H "Content-Type: application/json" \
  -d '{"id":"123","name":"UpdatedRole","description":"Updated role"}'

# Brisanje role (treba vratiti 401 Unauthorized)
curl -X DELETE "http://localhost:8080/api/Role/123"
```

## Konfiguracija sigurnosti

### JWT konfiguracija
```json
{
  "JwtSettings": {
    "SecretKey": "your-secret-key-here",
    "Issuer": "KartaAPI",
    "Audience": "KartaUsers",
    "ExpiryMinutes": 60,
    "RefreshTokenExpiryDays": 7
  }
}
```

### Email konfiguracija
```json
{
  "EmailSettings": {
    "SmtpServer": "smtp.gmail.com",
    "SmtpPort": 587,
    "SmtpUsername": "amar.omerovic0607@gmail.com",
    "SmtpPassword": "your-app-password",
    "FromEmail": "amar.omerovic0607@gmail.com",
    "FromName": "Karta Support"
  }
}
```

## Preporuke za buduće sigurnosne mjere

### Kratkoročne (1-2 tjedna)
- [ ] Implementirati rate limiting za API endpoint-e
- [ ] Dodati CORS konfiguraciju za frontend
- [ ] Implementirati email potvrdu za registraciju (trenutno je implementirano ali nije obavezno)

### Srednjoročne (1-2 mjeseca)
- [ ] Implementirati 2FA (Two-Factor Authentication)
- [ ] Dodati audit log za sve sigurnosne akcije
- [ ] Implementirati session management
- [ ] Dodati IP whitelisting za admin endpoint-e

### Dugoročne (3+ mjeseca)
- [ ] Implementirati OAuth2/OpenID Connect
- [ ] Dodati advanced threat detection
- [ ] Implementirati data encryption at rest
- [ ] Dodati security headers (HSTS, CSP, etc.)

## Kontakt za sigurnosne probleme

Ako pronađete sigurnosni problem, molimo kontaktirajte:
- **Email**: amar.omerovic0607@gmail.com
- **Prioritet**: Visok
- **Response time**: 24 sata

---

**Poslednje ažuriranje**: 10. septembar 2025.
**Verzija**: 1.0.0
