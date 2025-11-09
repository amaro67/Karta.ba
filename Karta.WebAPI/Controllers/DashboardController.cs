using Karta.Model;
using Karta.Service.DTO;
using Karta.WebAPI.Authorization;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Swashbuckle.AspNetCore.Annotations;

namespace Karta.WebAPI.Controllers
{
    /// <summary>
    /// Kontroler za admin dashboard statistike
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    [SwaggerTag("Admin Dashboard - Statistike i pregledi")]
    public class DashboardController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly ILogger<DashboardController> _logger;

        public DashboardController(
            ApplicationDbContext context,
            UserManager<ApplicationUser> userManager,
            ILogger<DashboardController> logger)
        {
            _context = context;
            _userManager = userManager;
            _logger = logger;
        }

        /// <summary>
        /// Vraća statistike za admin dashboard
        /// </summary>
        [HttpGet("stats")]
        [RequirePermission("ManageUsers")]
        [SwaggerOperation(
            Summary = "Vraća statistike",
            Description = "Vraća ukupnu zaradu, broj događaja, broj korisnika i profit"
        )]
        [SwaggerResponse(200, "Statistike", typeof(DashboardStatsResponse))]
        [SwaggerResponse(401, "Neautorizovan pristup")]
        [SwaggerResponse(403, "Nedovoljna prava")]
        public async Task<ActionResult<DashboardStatsResponse>> GetStats()
        {
            try
            {
                // Ukupna zarada (samo uspješne narudžbe)
                // SQLite ne podržava SumAsync direktno, pa učitavamo u memoriju pa računamo
                var completedOrders = await _context.Orders
                    .Where(o => o.Status == "Completed" || o.Status == "Paid")
                    .Select(o => o.TotalAmount)
                    .ToListAsync();
                var totalRevenue = completedOrders.Sum();

                // Broj događaja (samo aktivni, ne arhivirani)
                var numberOfEvents = await _context.Events
                    .Where(e => e.Status != "Archived")
                    .CountAsync();

                // Broj registrovanih korisnika
                var totalUsers = await _userManager.Users.CountAsync();

                // Profit karta.ba (ukupna zarada - provizija od 5%)
                // Možeš prilagoditi proviziju prema potrebi
                const decimal commissionRate = 0.05m; // 5% provizija
                var kartaBaProfit = totalRevenue * (1 - commissionRate);

                var stats = new DashboardStatsResponse(
                    TotalRevenue: totalRevenue,
                    NumberOfEvents: numberOfEvents,
                    TotalUsersRegistered: totalUsers,
                    KartaBaProfit: kartaBaProfit
                );

                _logger.LogInformation("Dashboard stats retrieved: Revenue={Revenue}, Events={Events}, Users={Users}, Profit={Profit}",
                    totalRevenue, numberOfEvents, totalUsers, kartaBaProfit);

                return Ok(stats);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving dashboard stats");
                return StatusCode(500, new { message = "Greška pri dohvaćanju statistika" });
            }
        }

        /// <summary>
        /// Vraća nadolazeće događaje
        /// </summary>
        [HttpGet("upcoming-events")]
        [RequirePermission("ManageUsers")]
        [SwaggerOperation(
            Summary = "Vraća nadolazeće događaje",
            Description = "Vraća listu nadolazećih događaja za prikaz na dashboardu"
        )]
        [SwaggerResponse(200, "Lista nadolazećih događaja", typeof(IReadOnlyList<UpcomingEventDto>))]
        [SwaggerResponse(401, "Neautorizovan pristup")]
        [SwaggerResponse(403, "Nedovoljna prava")]
        public async Task<ActionResult<IReadOnlyList<UpcomingEventDto>>> GetUpcomingEvents(
            [FromQuery] int limit = 5)
        {
            try
            {
                var now = DateTimeOffset.UtcNow;
                var nowDateTime = now.DateTime;

                // SQLite ima problema sa DateTimeOffset comparison, pa učitavamo sve pa filtriramo
                var allEvents = await _context.Events
                    .Include(e => e.PriceTiers)
                    .Where(e => e.Status != "Archived")
                    .ToListAsync();

                var upcomingEvents = allEvents
                    .Where(e => e.StartsAt.DateTime > nowDateTime)
                    .OrderBy(e => e.StartsAt)
                    .Take(limit)
                    .ToList();

                var eventsDto = upcomingEvents.Select(e =>
                {
                    var minPrice = e.PriceTiers.Any() 
                        ? e.PriceTiers.Min(pt => pt.Price) 
                        : 0;
                    var currency = e.PriceTiers.Any() 
                        ? e.PriceTiers.First().Currency 
                        : "BAM";

                    return new UpcomingEventDto(
                        Id: e.Id,
                        Title: e.Title,
                        StartsAt: e.StartsAt,
                        Location: e.Venue,
                        City: e.City,
                        PriceFrom: minPrice,
                        Currency: currency
                    );
                }).ToList();

                _logger.LogInformation("Retrieved {Count} upcoming events", eventsDto.Count);
                return Ok(eventsDto);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving upcoming events");
                return StatusCode(500, new { message = "Greška pri dohvaćanju nadolazećih događaja" });
            }
        }
    }
}

