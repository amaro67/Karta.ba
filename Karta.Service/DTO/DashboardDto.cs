using System;
using System.Collections.Generic;

namespace Karta.Service.DTO
{
    /// <summary>
    /// Statistike za admin dashboard
    /// </summary>
    public record DashboardStatsResponse(
        /// <summary>
        /// Ukupna zarada (total revenue)
        /// </summary>
        decimal TotalRevenue,
        
        /// <summary>
        /// Broj događaja
        /// </summary>
        int NumberOfEvents,
        
        /// <summary>
        /// Broj registrovanih korisnika
        /// </summary>
        int TotalUsersRegistered,
        
        /// <summary>
        /// Profit karta.ba (ukupna zarada minus provizije)
        /// </summary>
        decimal KartaBaProfit
    );

    /// <summary>
    /// DTO za nadolazeće događaje
    /// </summary>
    public record UpcomingEventDto(
        /// <summary>
        /// ID događaja
        /// </summary>
        Guid Id,
        
        /// <summary>
        /// Naziv događaja
        /// </summary>
        string Title,
        
        /// <summary>
        /// Datum i vrijeme
        /// </summary>
        DateTimeOffset StartsAt,
        
        /// <summary>
        /// Lokacija
        /// </summary>
        string Location,
        
        /// <summary>
        /// Grad
        /// </summary>
        string City,
        
        /// <summary>
        /// Cijena od (najniža cijena)
        /// </summary>
        decimal PriceFrom,
        
        /// <summary>
        /// Valuta
        /// </summary>
        string Currency
    );
}

