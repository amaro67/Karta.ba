using Karta.WebAPI.Middleware;

namespace Karta.WebAPI.Extensions
{
    /// <summary>
    /// Extension metode za middleware konfiguraciju
    /// </summary>
    public static class MiddlewareExtensions
    {
        /// <summary>
        /// Dodaje global exception handling middleware
        /// </summary>
        /// <param name="app">WebApplication instance</param>
        /// <returns>WebApplication instance</returns>
        public static IApplicationBuilder UseGlobalExceptionHandling(this IApplicationBuilder app)
        {
            return app.UseMiddleware<GlobalExceptionMiddleware>();
        }
    }
}
