using System;
using Karta.Service.DTO;
using Karta.Service.Interfaces;
using Karta.Service.Services;
using Karta.WebAPI.Authorization;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using System.Security.Claims;

namespace Karta.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class OrderController : ControllerBase
    {
        private readonly IOrderService _orderService;
        private readonly IStripeService _stripeService;
        private readonly IWebHostEnvironment _environment;
        private readonly ILogger<OrderController> _logger;

        public OrderController(IOrderService orderService, IStripeService stripeService, IWebHostEnvironment environment, ILogger<OrderController> logger)
        {
            _orderService = orderService;
            _stripeService = stripeService;
            _environment = environment;
            _logger = logger;
        }

        [HttpPost("create-checkout-session")]
        [ProducesResponseType(typeof(object), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        public async Task<ActionResult<object>> CreateCheckoutSession(
            [FromBody] CreateCheckoutSessionRequest request,
            CancellationToken ct = default)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userId))
                return Unauthorized();

            try
            {
                var (orderId, sessionId, url) = await _stripeService.CreateCheckoutSessionAsync(request, userId, ct);
                return Ok(new { orderId, sessionId, url });
            }
            catch (ArgumentException ex)
            {
                return Problem(title: "Invalid request", detail: ex.Message, statusCode: 400);
            }
            catch (InvalidOperationException ex)
            {
                return Problem(title: "Operation not allowed", detail: ex.Message, statusCode: 400);
            }
        }

        [HttpPost("create-payment-intent")]
        [ProducesResponseType(typeof(object), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        [Obsolete("Use create-checkout-session instead")]
        public async Task<ActionResult<object>> CreatePaymentIntent(
            [FromBody] CreateOrderRequest request,
            CancellationToken ct = default)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userId))
                return Unauthorized();

            // Override userId from request with authenticated user
            request = request with { UserId = userId };

            try
            {
                var (orderId, clientSecret) = await _stripeService.CreatePaymentIntentAsync(request, ct);
                return Ok(new { orderId, clientSecret });
            }
            catch (ArgumentException ex)
            {
                return Problem(title: "Invalid request", detail: ex.Message, statusCode: 400);
            }
            catch (InvalidOperationException ex)
            {
                return Problem(title: "Operation not allowed", detail: ex.Message, statusCode: 400);
            }
        }

        [HttpGet("{id}")]
        [ProducesResponseType(typeof(OrderDto), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<ActionResult<OrderDto>> GetOrder(Guid id, CancellationToken ct = default)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userId))
                return Unauthorized();

            var order = await _orderService.GetOrderAsync(id, userId, ct);
            if (order == null)
                return NotFound();

            return Ok(order);
        }

        [HttpGet("admin/{id}")]
        [RequirePermission("ViewAllOrders")]
        [ProducesResponseType(typeof(OrderDto), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(StatusCodes.Status403Forbidden)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<ActionResult<OrderDto>> GetOrderAdmin(Guid id, CancellationToken ct = default)
        {
            var order = await _orderService.GetOrderByIdAsync(id, ct);
            if (order == null)
                return NotFound();

            return Ok(order);
        }

        [HttpGet("my-orders")]
        [ProducesResponseType(typeof(IReadOnlyList<OrderDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        public async Task<ActionResult<IReadOnlyList<OrderDto>>> GetMyOrders(CancellationToken ct = default)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userId))
                return Unauthorized();

            var orders = await _orderService.GetMyOrdersAsync(userId, ct);
            return Ok(orders);
        }

        [HttpGet("all")]
        [RequirePermission("ViewAllOrders")]
        [ProducesResponseType(typeof(PagedResult<OrderDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(StatusCodes.Status403Forbidden)]
        public async Task<ActionResult<PagedResult<OrderDto>>> GetAllOrders(
            [FromQuery] string? query,
            [FromQuery] string? userId,
            [FromQuery] string? status,
            [FromQuery] DateTimeOffset? from,
            [FromQuery] DateTimeOffset? to,
            [FromQuery] int page = 1,
            [FromQuery] int size = 20,
            CancellationToken ct = default)
        {
            if (page < 1) page = 1;
            if (size < 1 || size > 100) size = 20;

            var result = await _orderService.GetAllOrdersAsync(query, userId, status, from, to, page, size, ct);
            return Ok(result);
        }

        [HttpPost("webhook")]
        [AllowAnonymous]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> HandleWebhook(CancellationToken ct = default)
        {
            try
            {
                using var reader = new StreamReader(Request.Body);
                var json = await reader.ReadToEndAsync();
                var signature = Request.Headers["Stripe-Signature"].FirstOrDefault();
                
                await _orderService.HandleStripeWebhookAsync(json, signature, ct);
                return Ok();
            }
            catch (Exception ex)
            {
                return Problem(title: "Webhook processing failed", detail: ex.Message, statusCode: 400);
            }
        }

        [HttpDelete("clear-all")]
        [RequirePermission("ManageUsers")]
        [ApiExplorerSettings(IgnoreApi = true)]
        [ProducesResponseType(typeof(object), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(StatusCodes.Status403Forbidden)]
        public async Task<IActionResult> ClearAllOrders(CancellationToken ct = default)
        {
            if (!_environment.IsDevelopment())
                return Forbid();

            try
            {
                await _orderService.ClearAllOrdersAsync(ct);
                return Ok(new { message = "All orders, order items, and tickets have been cleared successfully" });
            }
            catch (Exception ex)
            {
                return Problem(title: "Error clearing orders", detail: ex.Message, statusCode: 400);
            }
        }

        [HttpGet("success")]
        [AllowAnonymous]
        public async Task<IActionResult> PaymentSuccess([FromQuery] string session_id, [FromQuery] string order_id, CancellationToken ct)
        {
            try
            {
                // For success page, we don't need user validation - just show order info
                // We'll get the order with a dummy userId since it's public success page
                var order = await _orderService.GetOrderAsync(Guid.Parse(order_id), "public", ct);
                
                if (order == null)
                {
                    return BadRequest("Order not found");
                }

                return Ok(new
                {
                    message = "Payment successful!",
                    orderId = order.Id,
                    status = order.Status,
                    sessionId = session_id,
                    totalAmount = order.TotalAmount,
                    currency = order.Currency,
                    items = order.Items.Select(oi => new
                    {
                        quantity = oi.Qty,
                        unitPrice = oi.UnitPrice
                    })
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing payment success for order {OrderId}", order_id);
                return Problem("Error processing payment success");
            }
        }

        [HttpGet("cancel")]
        [AllowAnonymous]
        public IActionResult PaymentCancel([FromQuery] string order_id)
        {
            return Ok(new
            {
                message = "Payment was cancelled",
                orderId = order_id,
                status = "Cancelled"
            });
        }
    }
}
