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
