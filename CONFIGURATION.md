# Karta.ba - Konfiguracija

## 1. Stripe konfiguracija

### Korak 1: Kreiraj Stripe account
1. Idite na [stripe.com](https://stripe.com) i kreirajte account
2. U Stripe Dashboard-u, idite na "Developers" > "API keys"
3. Kopirajte "Publishable key" i "Secret key" (test mode)

### Korak 2: Konfiguriraj webhook
1. U Stripe Dashboard-u, idite na "Developers" > "Webhooks"
2. Kliknite "Add endpoint"
3. URL: `https://yourdomain.com/api/order/webhook`
4. Odaberite events: `payment_intent.succeeded`, `payment_intent.payment_failed`
5. Kopirajte "Signing secret"

### Korak 3: Ažuriraj appsettings.json
```json
{
  "Stripe": {
    "SecretKey": "sk_test_your_stripe_secret_key_here",
    "PublishableKey": "pk_test_your_stripe_publishable_key_here",
    "WebhookSecret": "whsec_your_webhook_secret_here"
  }
}
```

## 2. Email konfiguracija

### Opcija 1: Gmail SMTP
```json
{
  "Email": {
    "FromEmail": "noreply@karta.ba",
    "FromName": "Karta.ba",
    "SmtpHost": "smtp.gmail.com",
    "SmtpPort": 587,
    "SmtpUsername": "your_email@gmail.com",
    "SmtpPassword": "your_app_password",
    "EnableSsl": true
  }
}
```

**Gmail App Password:**
1. Idite na Google Account settings
2. Security > 2-Step Verification (mora biti uključeno)
3. App passwords > Generate app password
4. Koristite app password umjesto obične lozinke

### Opcija 2: SendGrid
```json
{
  "Email": {
    "FromEmail": "noreply@karta.ba",
    "FromName": "Karta.ba",
    "SmtpHost": "smtp.sendgrid.net",
    "SmtpPort": 587,
    "SmtpUsername": "apikey",
    "SmtpPassword": "your_sendgrid_api_key",
    "EnableSsl": true
  }
}
```

### Opcija 3: Outlook/Hotmail
```json
{
  "Email": {
    "FromEmail": "noreply@karta.ba",
    "FromName": "Karta.ba",
    "SmtpHost": "smtp-mail.outlook.com",
    "SmtpPort": 587,
    "SmtpUsername": "your_email@outlook.com",
    "SmtpPassword": "your_password",
    "EnableSsl": true
  }
}
```

## 3. Environment Variables (Preporučeno za produkciju)

Umjesto hardkodiranja u appsettings.json, koristite environment variables:

```bash
export Stripe__SecretKey="sk_test_your_stripe_secret_key_here"
export Stripe__PublishableKey="pk_test_your_stripe_publishable_key_here"
export Stripe__WebhookSecret="whsec_your_webhook_secret_here"
export Email__SmtpUsername="your_email@gmail.com"
export Email__SmtpPassword="your_app_password"
```

## 4. Testiranje

### Testiranje Stripe-a
1. Koristite test mode ključeve
2. Test kartice:
   - Success: `4242 4242 4242 4242`
   - Decline: `4000 0000 0000 0002`
   - 3D Secure: `4000 0025 0000 3155`

### Testiranje Email-a
1. Ako email nije konfiguriran, poruke će se samo logirati u konzoli
2. Provjerite logove za email sadržaj

## 5. Produkcija

### Stripe Live Mode
1. U Stripe Dashboard-u, prebacite na "Live mode"
2. Kopirajte live ključeve
3. Ažuriraj webhook URL na live domenu

### Email u produkciji
1. Koristite profesionalni email servis (SendGrid, Mailgun, itd.)
2. Konfiguriraj SPF, DKIM, DMARC records
3. Koristite environment variables za sigurnost

## 6. Sigurnost

⚠️ **VAŽNO:**
- Nikad ne commitajte prave ključeve u Git
- Koristite environment variables u produkciji
- Redovno rotirajte API ključeve
- Koristite HTTPS u produkciji
- Konfiguriraj CORS pravilno

## 7. Troubleshooting

### Stripe greške
- Provjerite da li su ključevi ispravni
- Provjerite webhook URL i signing secret
- Provjerite da li su events odabrani

### Email greške
- Provjerite SMTP credentials
- Provjerite da li je 2FA uključeno za Gmail
- Provjerite firewall settings
- Provjerite da li je SSL/TLS ispravno konfiguriran
