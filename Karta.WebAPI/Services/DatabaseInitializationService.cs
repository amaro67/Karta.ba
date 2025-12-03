using Karta.Model;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace Karta.WebAPI.Services
{
    public class DatabaseInitializationService : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<DatabaseInitializationService> _logger;

        public DatabaseInitializationService(
            IServiceProvider serviceProvider,
            ILogger<DatabaseInitializationService> logger)
        {
            _serviceProvider = serviceProvider;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("Database initialization service starting...");

            // Wait a bit to ensure the application is fully started
            await Task.Delay(1000, stoppingToken);

            try
            {
                using var scope = _serviceProvider.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

                // Ensure database exists (this is fast if it already exists)
                // Using EnsureCreatedAsync which is optimized for SQLite
                _logger.LogInformation("Ensuring database exists...");
                await context.Database.EnsureCreatedAsync(stoppingToken);
                _logger.LogInformation("Database ready.");

                // Initialize core roles
                _logger.LogInformation("Initializing core roles...");
                await RoleManagementService.InitializeCoreRoles(scope.ServiceProvider);
                _logger.LogInformation("Core roles initialized.");

                // Seed admin user
                _logger.LogInformation("Seeding admin user...");
                await SeedDataService.SeedAdminUser(scope.ServiceProvider);
                _logger.LogInformation("Admin user seeding completed.");

                _logger.LogInformation("Database initialization completed successfully.");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during database initialization");
            }
        }
    }
}
