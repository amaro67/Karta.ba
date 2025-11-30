# Security Setup Guide

## ⚠️ IMPORTANT: API Keys and Secrets Management

This guide will help you securely manage your API keys and sensitive configuration.

## 🔒 What We've Done

1. **Protected sensitive files** via `.gitignore`:
   - `appsettings.Development.json`
   - `docker-compose.yml`
   - All `.env` files

2. **Created safe templates** for version control:
   - `env.example` - Environment variables template
   - `env.production.example` - Production environment template
   - `appsettings.Development.example.json` - Development config template
   - `docker-compose.example.yml` - Docker compose template

3. **Updated `appsettings.json`** to use environment variables with fallback defaults

## 🚀 Initial Setup (For New Developers)

### Step 1: Create Your Local .env File

Copy the example file and add your actual secrets:

```bash
cp env.example .env
```

Then edit `.env` with your actual values:

```bash
# Use your actual Stripe test keys from https://dashboard.stripe.com/apikeys
STRIPE_SECRET_KEY=sk_test_your_actual_key_here
STRIPE_PUBLISHABLE_KEY=pk_test_your_actual_key_here
STRIPE_WEBHOOK_SECRET=whsec_your_actual_secret_here

# Use Gmail App Password from https://myaccount.google.com/apppasswords
EMAIL_SMTP_PASSWORD=your_actual_app_password_here

# Generate a strong JWT secret (at least 32 characters)
JWT_SECRET_KEY=your_actual_super_secret_key_here
```

### Step 2: Create Your Development Config

```bash
cd Karta.WebAPI
cp appsettings.Development.example.json appsettings.Development.json
```

Then edit `appsettings.Development.json` with your actual development secrets.

### Step 3: Create Your Docker Compose File

```bash
cp docker-compose.example.yml docker-compose.yml
```

Docker Compose will automatically read from your `.env` file.

## 🧹 If You've Already Committed Secrets

If you've already pushed secrets to GitHub, follow these steps:

### Step 1: Remove Secrets from Git History

```bash
# Remove sensitive files from git history
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch Karta.WebAPI/appsettings.Development.json" \
  --prune-empty --tag-name-filter cat -- --all

git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch docker-compose.yml" \
  --prune-empty --tag-name-filter cat -- --all

git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch env.example" \
  --prune-empty --tag-name-filter cat -- --all
```

Or use BFG Repo-Cleaner (faster method):

```bash
# Install BFG (macOS)
brew install bfg

# Remove passwords from history
bfg --replace-text passwords.txt

# Clean up
git reflog expire --expire=now --all
git gc --prune=now --aggressive
```

### Step 2: Force Push (⚠️ Warning: Rewrites History)

```bash
git push origin --force --all
git push origin --force --tags
```

### Step 3: Rotate All Compromised Secrets

**CRITICAL:** After removing secrets from history, you MUST rotate them:

1. **Stripe Keys**:
   - Go to https://dashboard.stripe.com/apikeys
   - Delete the exposed test keys
   - Generate new test keys
   - Update your local `.env` file

2. **Gmail App Password**:
   - Go to https://myaccount.google.com/apppasswords
   - Revoke the exposed password
   - Generate a new app password
   - Update your local `.env` file

3. **JWT Secret Key**:
   - Generate a new strong random key (at least 32 characters)
   - Update your local `.env` file

4. **Database Passwords**:
   - Update SQL Server SA password
   - Update your local `.env` file

## ✅ Best Practices Going Forward

1. **Never commit these files**:
   - `.env` files
   - `appsettings.Development.json`
   - `docker-compose.yml` (use example instead)

2. **Always use environment variables** for:
   - API keys
   - Passwords
   - Database connection strings
   - JWT secrets
   - Email credentials

3. **Use example files** for version control:
   - `env.example` - with placeholder values
   - `appsettings.Development.example.json` - with placeholder values
   - `docker-compose.example.yml` - with environment variable references

4. **Check before committing**:
   ```bash
   # Review what you're about to commit
   git diff --cached
   
   # Make sure no secrets are being committed
   git status
   ```

## 🔍 Verify Your Setup

Run this command to ensure no secrets are staged:

```bash
git status --short
```

You should see `.gitignore` and template files (`.example` files) as modified/new, but NOT:
- `appsettings.Development.json`
- `docker-compose.yml`
- `.env`

## 📚 Additional Resources

- [GitHub: Removing sensitive data](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)
- [Stripe: API Key Security](https://stripe.com/docs/keys#keeping-your-keys-safe)
- [Google: App Passwords](https://support.google.com/accounts/answer/185833)

## ❓ Questions?

If you're unsure about anything, ask before committing!

