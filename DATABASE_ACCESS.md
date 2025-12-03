# Pristup SQL Server Bazi Podataka u Dockeru

Vaša SQL Server baza je pokrenuta u Docker kontejneru `karta-sqlserver`. Evo nekoliko načina kako možete pristupiti bazi:

## 🔑 Kredencijali za pristup

- **Server:** `localhost` ili `127.0.0.1`
- **Port:** `1433`
- **Username:** `sa`
- **Password:** `KartaPassword2024!`
- **Database:** `KartaDb`

## 📋 Metode pristupa

### 1. Azure Data Studio (Preporučeno)

Azure Data Studio je besplatan, cross-platform alat za SQL Server.

**Instalacija:**
- Preuzmite sa: https://azure.microsoft.com/en-us/products/data-studio/

**Povezivanje:**
1. Otvorite Azure Data Studio
2. Kliknite na "New Connection"
3. Unesite sledeće podatke:
   - **Connection type:** Microsoft SQL Server
   - **Server:** `localhost,1433`
   - **Authentication type:** SQL Login
   - **User name:** `sa`
   - **Password:** `KartaPassword2024!`
   - **Database name:** `KartaDb`
   - **Trust server certificate:** ✅ (check)
4. Kliknite "Connect"

### 2. SQL Server Management Studio (SSMS)

SSMS je Microsoft-ov zvanični alat za SQL Server.

**Instalacija:**
- Preuzmite sa: https://learn.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms

**Povezivanje:**
1. Otvorite SSMS
2. U "Connect to Server" dijalogu unesite:
   - **Server type:** Database Engine
   - **Server name:** `localhost,1433` ili `127.0.0.1,1433`
   - **Authentication:** SQL Server Authentication
   - **Login:** `sa`
   - **Password:** `KartaPassword2024!`
3. Kliknite "Options" → "Connection Properties" → "Connect to database:" → `KartaDb`
4. Kliknite "Connect"

### 3. VS Code sa SQL Server ekstenzijom

**Instalacija ekstenzije:**
1. Otvorite VS Code
2. Idite na Extensions (Cmd+Shift+X)
3. Pretražite "SQL Server (mssql)"
4. Instalirajte ekstenziju

**Povezivanje:**
1. Pritisnite `Cmd+Shift+P` (Mac) ili `Ctrl+Shift+P` (Windows/Linux)
2. Kucajte "SQL: Connect"
3. Unesite connection string:
   ```
   Server=localhost,1433;Database=KartaDb;User Id=sa;Password=KartaPassword2024!;TrustServerCertificate=true;
   ```

### 4. Docker Exec (Command Line)

Možete koristiti `docker exec` za direktan pristup kontejneru:

```bash
# Pristup bash shell-u u kontejneru
docker exec -it karta-sqlserver bash

# Zatim možete koristiti sqlcmd (ako je dostupan)
sqlcmd -S localhost -U sa -P "KartaPassword2024!" -d KartaDb
```

### 5. Connection String za .NET aplikacije

Ako želite da se povežete iz .NET aplikacije:

```
Server=localhost,1433;Database=KartaDb;User Id=sa;Password=KartaPassword2024!;TrustServerCertificate=true;MultipleActiveResultSets=true;
```

## 🔍 Provera da li je baza dostupna

```bash
# Provera da li kontejner radi
docker ps | grep karta-sqlserver

# Provera logova
docker logs karta-sqlserver

# Test konekcije (zahteva sqlcmd)
docker exec karta-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "KartaPassword2024!" -Q "SELECT @@VERSION"
```

## 📊 Korisne SQL komande

Nakon povezivanja, možete koristiti sledeće komande:

```sql
-- Lista svih baza
SELECT name FROM sys.databases;

-- Lista svih tabela u KartaDb
USE KartaDb;
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES;

-- Lista svih korisnika
SELECT * FROM AspNetUsers;

-- Lista svih događaja
SELECT * FROM Events;
```

## ⚠️ Napomene

1. **Trust Server Certificate:** Azure SQL Edge zahteva `TrustServerCertificate=true` u connection string-u
2. **Port:** Port 1433 je mapiran na localhost, tako da možete pristupiti direktno
3. **Firewall:** Ako imate problema sa konekcijom, proverite da li firewall blokira port 1433

## 🐛 Rešavanje problema

**Problem: "Cannot connect to server"**
- Proverite da li kontejner radi: `docker ps`
- Proverite logove: `docker logs karta-sqlserver`
- Proverite da li je port 1433 slobodan: `lsof -i :1433`

**Problem: "Login failed"**
- Proverite da li koristite tačne kredencijale
- Proverite da li je password: `KartaPassword2024!` (sa velikim slovom K i !)

**Problem: "Database does not exist"**
- Baza se kreira automatski pri prvom pokretanju API-ja
- Proverite logove API kontejnera: `docker logs karta-api`

