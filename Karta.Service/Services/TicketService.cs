using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Karta.Model;
using Karta.Model.Entities;
using Karta.Service.DTO;
using Karta.Service.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Karta.Service.Services
{
    public class TicketService : ITicketService
    {
        private readonly ApplicationDbContext _context;

        public TicketService(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<IReadOnlyList<TicketDto>> GetMyTicketsAsync(string userId, CancellationToken ct = default)
        {
            var tickets = await _context.Tickets
                .Include(t => t.OrderItem)
                    .ThenInclude(oi => oi.Order)
                .Where(t => t.OrderItem.Order.UserId == userId)
                .OrderByDescending(t => t.IssuedAt)
                .ToListAsync(ct);

            return tickets.Select(t => new TicketDto(
                t.Id,
                t.TicketCode,
                t.Status,
                t.IssuedAt,
                t.UsedAt
            )).ToList();
        }

        public async Task<TicketDto?> GetTicketAsync(Guid id, string userId, CancellationToken ct = default)
        {
            var ticket = await _context.Tickets
                .Include(t => t.OrderItem)
                    .ThenInclude(oi => oi.Order)
                .FirstOrDefaultAsync(t => t.Id == id && t.OrderItem.Order.UserId == userId, ct);

            if (ticket == null)
                return null;

            return new TicketDto(
                ticket.Id,
                ticket.TicketCode,
                ticket.Status,
                ticket.IssuedAt,
                ticket.UsedAt
            );
        }

        public async Task<(string status, DateTime? usedAt)> ScanAsync(ScanTicketRequest req, CancellationToken ct = default)
        {
            var ticket = await _context.Tickets
                .Include(t => t.OrderItem)
                    .ThenInclude(oi => oi.Order)
                .FirstOrDefaultAsync(t => t.TicketCode == req.TicketCode, ct);

            if (ticket == null)
            {
                // Log invalid scan
                await LogScanAsync(Guid.Empty, req.GateId, "Invalid", ct);
                return ("Invalid", null);
            }

            // Check if ticket is already used
            if (ticket.Status == "Used")
            {
                await LogScanAsync(ticket.Id, req.GateId, "AlreadyUsed", ct);
                return ("AlreadyUsed", ticket.UsedAt);
            }

            // Check if order is paid
            if (ticket.OrderItem.Order.Status != "Paid")
            {
                await LogScanAsync(ticket.Id, req.GateId, "Unpaid", ct);
                return ("Unpaid", null);
            }

            // Mark ticket as used
            ticket.Status = "Used";
            ticket.UsedAt = DateTime.UtcNow;

            // Log successful scan
            await LogScanAsync(ticket.Id, req.GateId, "Valid", ct);

            await _context.SaveChangesAsync(ct);

            return ("Valid", ticket.UsedAt);
        }

        public async Task<TicketDto?> ValidateAsync(string ticketCode, CancellationToken ct = default)
        {
            var ticket = await _context.Tickets
                .Include(t => t.OrderItem)
                    .ThenInclude(oi => oi.Order)
                .FirstOrDefaultAsync(t => t.TicketCode == ticketCode, ct);

            if (ticket == null)
                return null;

            return new TicketDto(
                ticket.Id,
                ticket.TicketCode,
                ticket.Status,
                ticket.IssuedAt,
                ticket.UsedAt
            );
        }

        private async Task LogScanAsync(Guid ticketId, string gateId, string result, CancellationToken ct)
        {
            var scanLog = new ScanLog
            {
                Id = Guid.NewGuid(),
                TicketId = ticketId,
                GateId = gateId,
                ScannedAt = DateTime.UtcNow,
                Result = result
            };

            _context.ScanLogs.Add(scanLog);
            await _context.SaveChangesAsync(ct);
        }
    }
}
