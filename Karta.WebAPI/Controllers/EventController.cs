using Karta.Model;
using Karta.Service.DTO;
using Karta.Service.Interfaces;
using Karta.WebAPI.Authorization;
using Karta.WebAPI.Filters;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Swashbuckle.AspNetCore.Annotations;
using System.Security.Claims;
using System.Linq;

namespace Karta.WebAPI.Controllers
{
    /// <summary>
    /// Kontroler za upravljanje eventima
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    [SwaggerTag("Upravljanje eventima - kreiranje, ažuriranje, brisanje i pretraživanje eventa")]
    [ServiceFilter(typeof(ValidationFilterAttribute))]
    public class EventController : ControllerBase
    {
        private readonly IEventService _eventService;
            private readonly UserManager<ApplicationUser> _userManager;

        public EventController(IEventService eventService, UserManager<ApplicationUser> userManager)
        {
            _eventService = eventService;
            _userManager = userManager;
        }

        [HttpGet]
        public async Task<ActionResult<PagedResult<EventDto>>> GetEvents(
            [FromQuery] string? query,
            [FromQuery] string? category,
            [FromQuery] string? city,
            [FromQuery] DateTimeOffset? from,
            [FromQuery] DateTimeOffset? to,
            [FromQuery] int page = 1,
            [FromQuery] int size = 20)
        {
            if (page < 1) page = 1;
            if (size < 1 || size > 100) size = 20;

            var result = await _eventService.GetEventsAsync(query, category, city, from, to, page, size);
            return Ok(result);
        }

        [HttpGet("all")]
        [Authorize]
        [SwaggerOperation(Summary = "Dohvata sve evente za admin panel (uključujući archived)", 
                         Description = "Vraća sve evente sa mogućnošću filtriranja po statusu. Dostupno samo za autentifikovane korisnike.")]
        [SwaggerResponse(200, "Uspešno vraćena lista eventa", typeof(PagedResult<EventDto>))]
        [SwaggerResponse(401, "Korisnik nije autentifikovan")]
        public async Task<ActionResult<PagedResult<EventDto>>> GetAllEvents(
            [FromQuery] string? query,
            [FromQuery] string? category,
            [FromQuery] string? city,
            [FromQuery] string? status,
            [FromQuery] DateTimeOffset? from,
            [FromQuery] DateTimeOffset? to,
            [FromQuery] int page = 1,
            [FromQuery] int size = 20)
        {
            if (page < 1) page = 1;
            if (size < 1 || size > 100) size = 20;

            var result = await _eventService.GetAllEventsAsync(query, category, city, status, from, to, page, size);
            return Ok(result);
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<EventDto>> GetEvent(Guid id)
        {
            var eventDto = await _eventService.GetEventAsync(id);
            if (eventDto == null)
                return NotFound();

            return Ok(eventDto);
        }

        [HttpPost]
        [RequirePermission("CreateEvents")]
        public async Task<ActionResult<EventDto>> CreateEvent([FromBody] CreateEventRequest request)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userId))
                return Unauthorized();

            var user = await _userManager.FindByIdAsync(userId);
            if (user == null)
                return Unauthorized();

            try
            {
                var eventDto = await _eventService.CreateEventAsync(request, userId);
                return CreatedAtAction(nameof(GetEvent), new { id = eventDto.Id }, eventDto);
            }
            catch (ArgumentException ex)
            {
                return BadRequest(ex.Message);
            }
        }

        [HttpPut("{id}")]
        [RequirePermission("EditOwnEvents")]
        public async Task<ActionResult<EventDto>> UpdateEvent(Guid id, [FromBody] UpdateEventRequest request)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userId))
                return Unauthorized();

            var user = await _userManager.FindByIdAsync(userId);
            if (user == null)
                return Unauthorized();

            var roles = await _userManager.GetRolesAsync(user);
            var isOrganizer = roles.Contains("Organizer");
            var isAdmin = roles.Contains("Admin");

            if (!string.IsNullOrEmpty(request.Status) &&
                request.Status.Equals("Published", StringComparison.OrdinalIgnoreCase) &&
                isOrganizer &&
                !isAdmin &&
                !user.IsOrganizerVerified)
            {
                return StatusCode(StatusCodes.Status403Forbidden, new { message = "Organizator mora biti verifikovan od strane admina prije objave događaja." });
            }

            try
            {
                var eventDto = await _eventService.UpdateEventAsync(id, request, userId);
                return Ok(eventDto);
            }
            catch (ArgumentException ex)
            {
                return NotFound(ex.Message);
            }
        }

        [HttpDelete("{id}")]
        [RequirePermission("DeleteOwnEvents")]
        public async Task<ActionResult> DeleteEvent(Guid id)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userId))
                return Unauthorized();

            var success = await _eventService.DeleteEventAsync(id, userId);
            if (!success)
                return NotFound();

            return NoContent();
        }

        [HttpPost("{id}/archive")]
        [Authorize]
        public async Task<ActionResult> ArchiveEvent(Guid id)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userId))
                return Unauthorized();

            var success = await _eventService.ArchiveEventAsync(id, userId);
            if (!success)
                return NotFound();

            return NoContent();
        }

        [HttpGet("my-events")]
        [Authorize]
        [SwaggerOperation(Summary = "Dohvata sve evente koje je kreirao trenutni korisnik", 
                         Description = "Vraća listu eventa koje je kreirao organizator, sortirane po datumu kreiranja (najnoviji prvi)")]
        [SwaggerResponse(200, "Uspešno vraćena lista eventa", typeof(IReadOnlyList<EventDto>))]
        [SwaggerResponse(401, "Korisnik nije autentifikovan")]
        public async Task<ActionResult<IReadOnlyList<EventDto>>> GetMyEvents()
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userId))
                return Unauthorized();

            var events = await _eventService.GetMyEventsAsync(userId);
            return Ok(events);
        }
    }
}
