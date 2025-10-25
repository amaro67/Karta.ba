using Karta.Service.DTO;
using Karta.Service.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace Karta.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class TicketController : ControllerBase
    {
        private readonly ITicketService _ticketService;

        public TicketController(ITicketService ticketService)
        {
            _ticketService = ticketService;
        }

        [HttpGet("my-tickets")]
        [Authorize]
        public async Task<ActionResult<IReadOnlyList<TicketDto>>> GetMyTickets()
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userId))
                return Unauthorized();

            var tickets = await _ticketService.GetMyTicketsAsync(userId);
            return Ok(tickets);
        }

        [HttpGet("{id}")]
        [Authorize]
        public async Task<ActionResult<TicketDto>> GetTicket(Guid id)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userId))
                return Unauthorized();

            var ticket = await _ticketService.GetTicketAsync(id, userId);
            if (ticket == null)
                return NotFound();

            return Ok(ticket);
        }

        [HttpPost("scan")]
        [AllowAnonymous] // This endpoint might be used by scanning devices
        public async Task<ActionResult<object>> ScanTicket([FromBody] ScanTicketRequest request)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            try
            {
                var (status, usedAt) = await _ticketService.ScanAsync(request);
                return Ok(new { status, usedAt });
            }
            catch (Exception ex)
            {
                return BadRequest(ex.Message);
            }
        }

        [HttpPost("validate")]
        [AllowAnonymous] // This endpoint might be used by scanning devices
        public async Task<ActionResult<TicketDto>> ValidateTicket([FromBody] ValidateTicketRequest request)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            try
            {
                var ticket = await _ticketService.ValidateAsync(request.TicketCode);
                if (ticket == null)
                    return NotFound("Ticket not found");

                return Ok(ticket);
            }
            catch (Exception ex)
            {
                return BadRequest(ex.Message);
            }
        }
    }
}
