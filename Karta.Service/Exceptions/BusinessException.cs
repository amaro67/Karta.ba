using System;

namespace Karta.Service.Exceptions
{
    /// <summary>
    /// Exception za business logic greške
    /// </summary>
    public class BusinessException : BaseException
    {
        public BusinessException(string message, string errorCode = "BUSINESS_ERROR", object? details = null) 
            : base(message, errorCode, 400, details)
        {
        }

        public BusinessException(string message, Exception innerException, string errorCode = "BUSINESS_ERROR", object? details = null) 
            : base(message, errorCode, 400, innerException, details)
        {
        }
    }
}
