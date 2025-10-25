using System;
using System.Collections.Generic;

namespace Karta.Service.DTO
{
    /// <summary>
    /// Standardizovani error response model
    /// </summary>
    public record ErrorResponse(
        /// <summary>
        /// Error kod za identifikaciju tipa greške
        /// </summary>
        string ErrorCode,
        
        /// <summary>
        /// Ljudski čitljiva poruka o grešci
        /// </summary>
        string Message,
        
        /// <summary>
        /// Detaljne informacije o grešci (opciono)
        /// </summary>
        object? Details = null,
        
        /// <summary>
        /// Validation greške (samo za validation error-e)
        /// </summary>
        Dictionary<string, string[]>? ValidationErrors = null,
        
        /// <summary>
        /// Timestamp kada se greška dogodila
        /// </summary>
        DateTime Timestamp = default,
        
        /// <summary>
        /// Request ID za tracking (opciono)
        /// </summary>
        string? RequestId = null,
        
        /// <summary>
        /// Stack trace (samo u development okruženju)
        /// </summary>
        string? StackTrace = null
    )
    {
        public ErrorResponse() : this(string.Empty, string.Empty)
        {
            Timestamp = DateTime.UtcNow;
        }
    }

    /// <summary>
    /// Validation error response model
    /// </summary>
    public record ValidationErrorResponse(
        string ErrorCode,
        string Message,
        Dictionary<string, string[]> ValidationErrors,
        DateTime Timestamp = default,
        string? RequestId = null
    ) : ErrorResponse(ErrorCode, Message, null, ValidationErrors, Timestamp, RequestId);

    /// <summary>
    /// API error response wrapper
    /// </summary>
    public record ApiErrorResponse(
        /// <summary>
        /// Indikator da li je request uspješan
        /// </summary>
        bool Success = false,
        
        /// <summary>
        /// Error response podaci
        /// </summary>
        ErrorResponse? Error = null,
        
        /// <summary>
        /// HTTP status kod
        /// </summary>
        int StatusCode = 500
    );
}
