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
    public class OrderService : IOrderService
    {
        private readonly ApplicationDbContext _context;
        private readonly IStripeService _stripeService;

        public OrderService(ApplicationDbContext context, IStripeService stripeService)
        {
            _context = context;
            _stripeService = stripeService;
        }

        public async Task<(Guid orderId, string clientSecret)> CreatePaymentIntentAsync(CreateOrderRequest req, CancellationToken ct = default)
        {
            var (orderId, clientSecret) = await _stripeService.CreatePaymentIntentAsync(req, ct);
            return (orderId, clientSecret);
        }

        public async Task<OrderDto?> GetOrderAsync(Guid id, string userId, CancellationToken ct = default)
        {
            var order = await _context.Orders
                .Include(o => o.Items)
                    .ThenInclude(oi => oi.Tickets)
                .FirstOrDefaultAsync(o => o.Id == id && o.UserId == userId, ct);

            if (order == null)
                return null;

            var orderItems = order.Items.Select(oi => new OrderItemDto(
                oi.Id,
                oi.EventId,
                oi.PriceTierId,
                oi.Qty,
                oi.UnitPrice,
                oi.Tickets.Select(t => new TicketDto(
                    t.Id,
                    t.TicketCode,
                    t.Status,
                    t.IssuedAt,
                    t.UsedAt
                )).ToList()
            )).ToList();

            return new OrderDto(
                order.Id,
                order.UserId,
                order.TotalAmount,
                order.Currency,
                order.Status,
                order.CreatedAt,
                orderItems
            );
        }

        public async Task<OrderDto?> GetOrderByIdAsync(Guid id, CancellationToken ct = default)
        {
            var order = await _context.Orders
                .Include(o => o.Items)
                    .ThenInclude(oi => oi.Tickets)
                .FirstOrDefaultAsync(o => o.Id == id, ct);

            if (order == null)
                return null;

            // Get user information
            var user = await _context.Users
                .FirstOrDefaultAsync(u => u.Id == order.UserId, ct);

            var orderItems = order.Items.Select(oi => new OrderItemDto(
                oi.Id,
                oi.EventId,
                oi.PriceTierId,
                oi.Qty,
                oi.UnitPrice,
                oi.Tickets.Select(t => new TicketDto(
                    t.Id,
                    t.TicketCode,
                    t.Status,
                    t.IssuedAt,
                    t.UsedAt
                )).ToList()
            )).ToList();

            return new OrderDto(
                order.Id,
                order.UserId,
                order.TotalAmount,
                order.Currency,
                order.Status,
                order.CreatedAt,
                orderItems,
                user?.FirstName,
                user?.LastName,
                user?.Email
            );
        }

        public async Task<IReadOnlyList<OrderDto>> GetMyOrdersAsync(string userId, CancellationToken ct = default)
        {
            var orders = await _context.Orders
                .Include(o => o.Items)
                    .ThenInclude(oi => oi.Tickets)
                .Where(o => o.UserId == userId)
                .OrderByDescending(o => o.CreatedAt)
                .ToListAsync(ct);

            return orders.Select(order => new OrderDto(
                order.Id,
                order.UserId,
                order.TotalAmount,
                order.Currency,
                order.Status,
                order.CreatedAt,
                order.Items.Select(oi => new OrderItemDto(
                    oi.Id,
                    oi.EventId,
                    oi.PriceTierId,
                    oi.Qty,
                    oi.UnitPrice,
                    oi.Tickets.Select(t => new TicketDto(
                        t.Id,
                        t.TicketCode,
                        t.Status,
                        t.IssuedAt,
                        t.UsedAt
                    )).ToList()
                )).ToList()
            )).ToList();
        }

        public async Task<PagedResult<OrderDto>> GetAllOrdersAsync(string? query, string? userId, string? status, DateTimeOffset? from, DateTimeOffset? to, int page, int size, CancellationToken ct = default)
        {
            var ordersQuery = _context.Orders
                .Include(o => o.Items)
                    .ThenInclude(oi => oi.Tickets)
                .AsQueryable();

            // Apply search query filter (order ID, user name, email)
            if (!string.IsNullOrEmpty(query))
            {
                // Try to parse as Guid for order ID search
                if (Guid.TryParse(query, out var orderId))
                {
                    ordersQuery = ordersQuery.Where(o => o.Id == orderId);
                }
                else
                {
                    // Search by user first name, last name, or email (case-insensitive)
                    // Load users into memory first due to SQLite limitations with ToLower()
                    var allUsers = await _context.Users
                        .Select(u => new { u.Id, u.FirstName, u.LastName, u.Email })
                        .ToListAsync(ct);

                    var queryLower = query.ToLower();
                    var matchingUserIds = allUsers
                        .Where(u => 
                            (u.FirstName != null && u.FirstName.ToLower().Contains(queryLower)) || 
                            (u.LastName != null && u.LastName.ToLower().Contains(queryLower)) || 
                            (u.Email != null && u.Email.ToLower().Contains(queryLower)))
                        .Select(u => u.Id)
                        .ToList();

                    if (matchingUserIds.Any())
                    {
                        ordersQuery = ordersQuery.Where(o => matchingUserIds.Contains(o.UserId));
                    }
                    else
                    {
                        // No matching users found, return empty result
                        ordersQuery = ordersQuery.Where(o => false);
                    }
                }
            }

            // Apply filters
            if (!string.IsNullOrEmpty(userId))
            {
                ordersQuery = ordersQuery.Where(o => o.UserId == userId);
            }

            if (!string.IsNullOrEmpty(status))
            {
                ordersQuery = ordersQuery.Where(o => o.Status == status);
            }

            if (from.HasValue)
            {
                ordersQuery = ordersQuery.Where(o => o.CreatedAt >= from.Value);
            }

            if (to.HasValue)
            {
                ordersQuery = ordersQuery.Where(o => o.CreatedAt <= to.Value);
            }

            var total = await ordersQuery.CountAsync(ct);

            // Load orders into memory first, then sort by DateTime (SQLite limitation)
            var ordersList = await ordersQuery
                .OrderByDescending(o => o.CreatedAt)
                .Skip((page - 1) * size)
                .Take(size)
                .ToListAsync(ct);

            // Get all user IDs from orders
            var userIds = ordersList.Select(o => o.UserId).Distinct().ToList();
            
            // Load user information
            var users = await _context.Users
                .Where(u => userIds.Contains(u.Id))
                .Select(u => new { u.Id, u.FirstName, u.LastName, u.Email })
                .ToListAsync(ct);
            
            var userDict = users.ToDictionary(u => u.Id);

            var ordersDto = ordersList.Select(order => 
            {
                var user = userDict.GetValueOrDefault(order.UserId);
                return new OrderDto(
                    order.Id,
                    order.UserId,
                    order.TotalAmount,
                    order.Currency,
                    order.Status,
                    order.CreatedAt,
                    order.Items.Select(oi => new OrderItemDto(
                        oi.Id,
                        oi.EventId,
                        oi.PriceTierId,
                        oi.Qty,
                        oi.UnitPrice,
                        oi.Tickets.Select(t => new TicketDto(
                            t.Id,
                            t.TicketCode,
                            t.Status,
                            t.IssuedAt,
                            t.UsedAt
                        )).ToList()
                    )).ToList(),
                    user?.FirstName,
                    user?.LastName,
                    user?.Email
                );
            }).ToList();

            return new PagedResult<OrderDto>
            {
                Items = ordersDto,
                Page = page,
                Size = size,
                Total = total
            };
        }

        public async Task<IReadOnlyList<OrganizerOrderDto>> GetOrganizerOrdersAsync(string organizerId, CancellationToken ct = default)
        {
            var events = await _context.Events
                .Where(e => e.CreatedBy == organizerId)
                .Select(e => e.Id)
                .ToListAsync(ct);

            if (!events.Any())
            {
                return Array.Empty<OrganizerOrderDto>();
            }

            var orderItems = await _context.OrderItems
                .Include(oi => oi.Order)
                .Include(oi => oi.Event)
                .Where(oi => events.Contains(oi.EventId))
                .AsNoTracking()
                .ToListAsync(ct);

            var userIds = orderItems
                .Select(oi => oi.Order.UserId)
                .Where(id => !string.IsNullOrEmpty(id))
                .Distinct()
                .ToList();

            var users = await _context.Users
                .Where(u => userIds.Contains(u.Id))
                .Select(u => new { u.Id, u.Email })
                .ToListAsync(ct);

            var userEmailLookup = users.ToDictionary(u => u.Id, u => u.Email ?? string.Empty);

            var groupedOrders = orderItems
                .GroupBy(oi => oi.OrderId)
                .Select(group =>
                {
                    var order = group.First().Order;
                    var eventTitle = group.First().Event?.Title ?? "Event";
                    var eventId = group.First().EventId;
                    var totalTickets = group.Sum(g => g.Qty);

                    return new OrganizerOrderDto(
                        order.Id,
                        userEmailLookup.GetValueOrDefault(order.UserId, string.Empty),
                        order.CreatedAt,
                        order.TotalAmount,
                        order.Currency,
                        order.Status,
                        eventTitle,
                        eventId,
                        totalTickets
                    );
                })
                .OrderByDescending(o => o.CreatedAt)
                .ToList();

            return groupedOrders;
        }

        public async Task HandleStripeWebhookAsync(string json, string? signature, CancellationToken ct = default)
        {
            await _stripeService.HandleWebhookAsync(json, signature, ct);
        }

        public async Task ClearAllOrdersAsync(CancellationToken ct = default)
        {
            // Delete all tickets first (due to foreign key constraints)
            var tickets = await _context.Tickets.ToListAsync(ct);
            _context.Tickets.RemoveRange(tickets);

            // Delete all order items
            var orderItems = await _context.OrderItems.ToListAsync(ct);
            _context.OrderItems.RemoveRange(orderItems);

            // Delete all orders
            var orders = await _context.Orders.ToListAsync(ct);
            _context.Orders.RemoveRange(orders);

            // Reset sold count in price tiers
            var priceTiers = await _context.PriceTiers.ToListAsync(ct);
            foreach (var priceTier in priceTiers)
            {
                priceTier.Sold = 0;
            }

            await _context.SaveChangesAsync(ct);
        }

    }
}
