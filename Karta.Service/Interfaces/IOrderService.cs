using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Karta.Service.DTO;

namespace Karta.Service.Interfaces;

public interface IOrderService
{
    Task<(Guid orderId, string clientSecret)> CreatePaymentIntentAsync(CreateOrderRequest req, CancellationToken ct = default);
    Task<OrderDto?> GetOrderAsync(Guid id, string userId, CancellationToken ct = default);
    Task<IReadOnlyList<OrderDto>> GetMyOrdersAsync(string userId, CancellationToken ct = default);
    Task HandleStripeWebhookAsync(string json, string? signature, CancellationToken ct = default);
    Task ClearAllOrdersAsync(CancellationToken ct = default);
}
