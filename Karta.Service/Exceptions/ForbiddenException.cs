using System;

namespace Karta.Service.Exceptions
{
    /// <summary>
    /// Exception za forbidden pristup
    /// </summary>
    public class ForbiddenException : BaseException
    {
        public ForbiddenException(string message = "Access forbidden", string errorCode = "FORBIDDEN", object? details = null) 
            : base(message, errorCode, 403, details)
        {
        }
    }
}
