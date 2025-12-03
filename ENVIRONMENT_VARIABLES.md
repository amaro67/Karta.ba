# Environment Variables Configuration

This document describes the environment variables used in the Karta.ba application for different environments.

## Overview

The application uses environment variables to configure sensitive data and environment-specific settings. This approach ensures that sensitive information like API keys and database connections are not hardcoded in the source code.

## Environment Files

- `env.example` - Template with all required environment variables (safe to commit)
- `.env` - Actual production values (DO NOT COMMIT - gitignored)
- `appsettings.json` - Production configuration using environment variables
- `appsettings.Development.json` - Development configuration with hardcoded test values

## Required Environment Variables

### Database Configuration
| Variable | Description | Example | Required |
|----------|-------------|---------|----------|
| `CONNECTION_STRING` | Database connection string | `Server=localhost,1433;Database=KartaDb;User Id=sa;Password=YourPassword;TrustServerCertificate=true;MultipleActiveResultSets=true;` | Yes |

### Stripe Configuration
| Variable | Description | Example | Required |
|----------|-------------|---------|----------|
| `STRIPE_SECRET_KEY` | Stripe secret key for API calls | `sk_live_...` | Yes |
| `STRIPE_PUBLISHABLE_KEY` | Stripe publishable key for frontend | `pk_live_...` | Yes |
| `STRIPE_WEBHOOK_SECRET` | Stripe webhook secret for verification | `whsec_...` | Yes |

### Email Configuration
| Variable | Description | Example | Required |
|----------|-------------|---------|----------|
| `EMAIL_FROM_EMAIL` | Sender email address | `noreply@karta.ba` | Yes |
| `EMAIL_SMTP_HOST` | SMTP server hostname | `smtp.gmail.com` | Yes |
| `EMAIL_SMTP_PORT` | SMTP server port | `587` | No (default: 587) |
| `EMAIL_SMTP_USERNAME` | SMTP username | `noreply@karta.ba` | Yes |
| `EMAIL_SMTP_PASSWORD` | SMTP password/app password | `your_app_password` | Yes |

### JWT Configuration
| Variable | Description | Example | Required |
|----------|-------------|---------|----------|
| `JWT_SECRET_KEY` | Secret key for JWT token signing | `your_32_char_secret_key` | Yes |
| `JWT_EXPIRY_MINUTES` | JWT token expiry in minutes | `60` | No (default: 60) |
| `JWT_REFRESH_TOKEN_EXPIRY_DAYS` | Refresh token expiry in days | `7` | No (default: 7) |

### Security Configuration
| Variable | Description | Example | Required |
|----------|-------------|---------|----------|
| `CORS_ALLOWED_ORIGINS` | Comma-separated list of allowed origins | `https://karta.ba,https://www.karta.ba` | Yes |
| `RATE_LIMIT_REQUESTS_PER_MINUTE` | Rate limit per minute | `100` | No (default: 100) |
| `RATE_LIMIT_BURST` | Rate limit burst capacity | `20` | No (default: 20) |

### Order Management
| Variable | Description | Example | Required |
|----------|-------------|---------|----------|
| `ORDER_CLEANUP_INTERVAL_MINUTES` | Order cleanup interval | `60` | No (default: 60) |
| `ORDER_EXPIRATION_HOURS` | Order expiration time | `24` | No (default: 24) |

### Logging Configuration
| Variable | Description | Example | Required |
|----------|-------------|---------|----------|
| `LOG_LEVEL` | Logging level | `Information` | No (default: Information) |
| `LOG_FILE_PATH` | Log file path | `logs/karta-.log` | No (default: logs/karta-.log) |
| `LOG_RETAINED_FILE_COUNT` | Number of log files to retain | `7` | No (default: 7) |

### Application Configuration
| Variable | Description | Example | Required |
|----------|-------------|---------|----------|
| `ALLOWED_HOSTS` | Allowed host headers | `*` | No (default: *) |

## Setting Up Production Environment

1. **Copy the template file:**
   ```bash
   cp env.example .env
   ```

2. **Fill in the actual values:**
   - Replace all placeholder values with your actual production values
   - Ensure JWT_SECRET_KEY is at least 32 characters long
   - Use production Stripe keys (sk_live_* and pk_live_*)
   - Set up proper email credentials

3. **Set environment variables:**
   - On your production server, set these environment variables
   - Or use a tool like `dotenv` to load from `.env`

4. **Verify configuration:**
   - Test the application in production mode
   - Check that all services (database, email, Stripe) are working

## Security Best Practices

1. **Never commit sensitive values** to version control
2. **Use strong, unique secrets** for JWT keys
3. **Rotate secrets regularly** in production
4. **Use environment-specific email addresses** (e.g., noreply@karta.ba)
5. **Restrict CORS origins** to your actual domains
6. **Monitor and log** access attempts
7. **Use HTTPS** in production

## Environment-Specific Notes

### Development
- Uses `appsettings.Development.json` with hardcoded test values
- Stripe test keys are used
- More verbose logging enabled
- Relaxed CORS and rate limiting for development

### Production
- Uses `appsettings.json` with environment variables
- Stripe live keys are used
- Optimized logging configuration
- Enhanced security settings

## Troubleshooting

### Common Issues
1. **Missing environment variables** - Check that all required variables are set
2. **Invalid JWT secret** - Ensure it's at least 32 characters long
3. **CORS errors** - Verify CORS_ALLOWED_ORIGINS includes your frontend domain
4. **Email not sending** - Check SMTP credentials and app password setup
5. **Stripe errors** - Verify you're using the correct environment keys

### Debugging
- Check application logs for configuration errors
- Use `dotnet user-secrets` for local development
- Verify environment variables are loaded correctly
