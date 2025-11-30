# 🔐 Secrets Rotation Checklist

## ⚠️ CRITICAL: Your secrets were exposed in git!

Since your API keys and passwords were in files that were (or will be) committed to git, you **MUST** rotate them immediately.

## 🚨 Immediate Actions Required

### 1. Stripe API Keys (HIGH PRIORITY)
- [ ] Go to https://dashboard.stripe.com/test/apikeys
- [ ] Click "Reveal test key token" for your Secret key
- [ ] Click "Roll key" to generate a new secret key
- [ ] Update your local `Karta.WebAPI/appsettings.Development.json` with the new key
- [ ] Do the same for Publishable key if needed
- [ ] Go to https://dashboard.stripe.com/test/webhooks
- [ ] Regenerate webhook signing secret
- [ ] Update your local files

### 2. Gmail App Password (HIGH PRIORITY)
Your exposed password: `glat uuwp rmos lobo`

- [ ] Go to https://myaccount.google.com/apppasswords
- [ ] Find and revoke the exposed app password
- [ ] Generate a new app password
- [ ] Update `EMAIL_SMTP_PASSWORD` in your local `Karta.WebAPI/appsettings.Development.json`

### 3. JWT Secret Key (MEDIUM PRIORITY)
- [ ] Generate a new strong random key (at least 32 characters)
  ```bash
  # Use this command to generate a secure key:
  openssl rand -base64 48
  ```
- [ ] Update `JWT_SECRET_KEY` in your local `Karta.WebAPI/appsettings.Development.json`

### 4. Database Passwords (LOW PRIORITY - Test DB)
Your exposed password: `KartaPassword2024!`

- [ ] Change SQL Server SA password
- [ ] Update local configuration files

## 📝 After Rotating Secrets

1. **Create your local `.env` file** (protected by .gitignore):
   ```bash
   cp env.example .env
   # Then edit .env with your NEW secrets
   ```

2. **Copy the development config**:
   ```bash
   cp Karta.WebAPI/appsettings.Development.example.json Karta.WebAPI/appsettings.Development.json
   # Then edit appsettings.Development.json with your NEW secrets
   ```

3. **Copy docker-compose**:
   ```bash
   cp docker-compose.example.yml docker-compose.yml
   # Docker will read secrets from your .env file
   ```

4. **Test your application** with the new secrets to ensure everything works

## ✅ Verify Protection

Run this before every commit:

```bash
git status
```

Make sure you NEVER see these files in "Changes to be committed":
- ❌ `appsettings.Development.json`
- ❌ `docker-compose.yml`
- ❌ `.env`

You SHOULD see these (they're safe templates):
- ✅ `appsettings.Development.example.json`
- ✅ `docker-compose.example.yml`
- ✅ `env.example`

## 📚 More Details

See `SECURITY_SETUP.md` for comprehensive security documentation.

---

**Remember:** Once secrets are in git history, they're compromised forever. Always rotate them!

