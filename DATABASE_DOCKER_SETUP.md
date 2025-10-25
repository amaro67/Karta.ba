# Karta.ba Database Docker Setup

This guide explains how to run the Karta.ba application with SQL Server database in Docker containers.

## 🗄️ Database Configuration

The application now uses **SQL Server 2022** running in a Docker container, which is perfect for enterprise applications and provides excellent performance and reliability.

### Key Features:
- **SQL Server 2022 Express** - Free edition with full functionality
- **Persistent data storage** - Database survives container restarts
- **Health checks** - Automatic monitoring of database status
- **Network isolation** - Secure communication between containers
- **Resource limits** - Optimized memory usage

## 🚀 Quick Start

### 1. Development Environment
```bash
# Start the database and application
docker-compose up -d

# Check logs
docker-compose logs -f karta-api

# Access the API
# http://localhost:8080
# http://localhost:8080/swagger
```

### 2. Production Environment
```bash
# Copy environment template
cp env.production.example .env

# Edit .env file with your production values
nano .env

# Start production environment
docker-compose -f docker-compose.production.yml up -d
```

## 🔧 Database Connection Details

### Development
- **Server**: `localhost,1433`
- **Database**: `KartaDb`
- **Username**: `sa`
- **Password**: `KartaPassword2024!`
- **Trust Server Certificate**: `true`

### Production
- **Server**: `localhost,1433`
- **Database**: `KartaDb`
- **Username**: `sa`
- **Password**: `${SQLSERVER_SA_PASSWORD}` (from .env file)
- **Trust Server Certificate**: `true`

## 📊 Database Management

### Connect with SQL Server Management Studio (SSMS)
1. Open SSMS
2. Server name: `localhost,1433`
3. Authentication: SQL Server Authentication
4. Login: `sa`
5. Password: `KartaPassword2024!` (dev) or your production password

### Connect with Azure Data Studio
1. Open Azure Data Studio
2. Connection type: Microsoft SQL Server
3. Server: `localhost,1433`
4. Authentication type: SQL Login
5. User name: `sa`
6. Password: `KartaPassword2024!` (dev) or your production password

### Run Migrations
```bash
# Run Entity Framework migrations
docker-compose run --rm karta-api dotnet ef database update

# Or use the migration script
./scripts/migrate-database.sh
```

## 🔄 Migration from SQLite

If you're migrating from SQLite to SQL Server:

1. **Backup your SQLite data** (if needed)
2. **Run the migration script**:
   ```bash
   ./scripts/migrate-database.sh
   ```
3. **Verify the migration** by checking the database tables

## 🛠️ Troubleshooting

### Database Connection Issues
```bash
# Check if SQL Server is running
docker-compose ps sqlserver

# Check SQL Server logs
docker-compose logs sqlserver

# Restart SQL Server
docker-compose restart sqlserver
```

### Application Issues
```bash
# Check application logs
docker-compose logs karta-api

# Rebuild and restart
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Memory Issues
If you encounter memory issues with SQL Server:
```bash
# Check container resource usage
docker stats

# Increase memory limits in docker-compose.yml
deploy:
  resources:
    limits:
      memory: 2G
```

## 📁 File Structure

```
├── docker-compose.yml              # Development environment
├── docker-compose.production.yml   # Production environment
├── Dockerfile                      # Application container
├── scripts/
│   ├── init-db.sql                 # Database initialization
│   └── migrate-database.sh          # Migration script
└── env.production.example          # Environment template
```

## 🔒 Security Notes

### Development
- Default password is used for convenience
- Database is accessible from localhost only
- SSL/TLS is not required for local development

### Production
- **Change the SA password** in production
- Use environment variables for sensitive data
- Consider using SSL/TLS for database connections
- Implement proper backup strategies

## 📈 Performance Optimization

### SQL Server Configuration
- **Memory**: 512MB minimum, 1GB recommended for production
- **CPU**: 1-2 cores recommended
- **Storage**: Use SSD for better performance

### Connection Pooling
The connection string includes optimized pooling settings:
- `Pooling=true`
- `MinPoolSize=0`
- `MaxPoolSize=100`
- `ConnectionLifetime=0`

## 🎯 Next Steps

1. **Test the setup**: Run `docker-compose up -d` and verify everything works
2. **Configure production**: Update `.env` file with your production values
3. **Set up monitoring**: Consider adding database monitoring tools
4. **Backup strategy**: Implement regular database backups
5. **Security review**: Review and harden security settings for production

## 📞 Support

If you encounter any issues:
1. Check the logs: `docker-compose logs -f`
2. Verify Docker is running: `docker info`
3. Check resource usage: `docker stats`
4. Review this documentation for troubleshooting steps
