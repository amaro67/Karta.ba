using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Karta.Model;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;

namespace Karta.WebAPI.Services
{
    public class EventArchiveService : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<EventArchiveService> _logger;
        private readonly TimeSpan _checkInterval;

        public EventArchiveService(
            IServiceProvider serviceProvider, 
            ILogger<EventArchiveService> logger,
            IConfiguration configuration)
        {
            _serviceProvider = serviceProvider;
            _logger = logger;
            
            // Get configuration values - default: check every hour
            var checkIntervalMinutes = configuration.GetValue<int>("EventArchive:CheckIntervalMinutes", 60);
            _checkInterval = TimeSpan.FromMinutes(checkIntervalMinutes);
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("EventArchiveService started. Check interval: {Interval}", _checkInterval);

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    await ArchiveExpiredEvents(stoppingToken);
                }
                catch (OperationCanceledException)
                {
                    // Expected when service is stopping
                    _logger.LogInformation("EventArchiveService is stopping");
                    break;
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error occurred during event archiving");
                }

                try
                {
                    await Task.Delay(_checkInterval, stoppingToken);
                }
                catch (OperationCanceledException)
                {
                    // Expected when service is stopping
                    _logger.LogInformation("EventArchiveService is stopping");
                    break;
                }
            }

            _logger.LogInformation("EventArchiveService stopped");
        }

        private async Task ArchiveExpiredEvents(CancellationToken cancellationToken)
        {
            using var scope = _serviceProvider.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
            
            var now = DateTimeOffset.UtcNow;
            var nowDateTime = now.DateTime;
            
            _logger.LogDebug("Looking for events that should be archived (current time: {Now})", now);

            // SQLite has issues with DateTimeOffset comparison, so load all non-archived/cancelled events first
            // then filter in memory
            var allEvents = await context.Events
                .Where(e => e.Status != "Archived" && e.Status != "Cancelled")
                .ToListAsync(cancellationToken);

            // Find events that should be archived:
            // - EndsAt has passed (or StartsAt if EndsAt is null)
            var eventsToArchive = allEvents
                .Where(e => (e.EndsAt.HasValue && e.EndsAt.Value.DateTime < nowDateTime) || 
                           (!e.EndsAt.HasValue && e.StartsAt.DateTime < nowDateTime))
                .ToList();

            if (eventsToArchive.Count == 0)
            {
                _logger.LogDebug("No events to archive");
                return;
            }

            _logger.LogInformation("Found {Count} event(s) to archive", eventsToArchive.Count);

            // Mark events as archived
            foreach (var eventEntity in eventsToArchive)
            {
                var endDate = eventEntity.EndsAt?.ToString() ?? eventEntity.StartsAt.ToString();
                eventEntity.Status = "Archived";
                _logger.LogInformation("Archiving event {EventId} ({Title}) - End date: {EndDate}", 
                    eventEntity.Id, eventEntity.Title, endDate);
            }

            // Save changes
            var archivedCount = await context.SaveChangesAsync(cancellationToken);
            
            _logger.LogInformation("Successfully archived {Count} event(s)", archivedCount);
        }
    }
}

