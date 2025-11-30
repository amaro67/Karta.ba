using System;
using System.ComponentModel.DataAnnotations;

namespace Karta.Service.DTO
{
    /// <summary>
    /// Zahtjev za prijavu korisnika
    /// </summary>
    public record LoginRequest(
        /// <summary>
        /// Email adresa korisnika
        /// </summary>
        [Required(ErrorMessage = "Email je obavezan")]
        [EmailAddress(ErrorMessage = "Neispravna email adresa")]
        string Email, 
        
        /// <summary>
        /// Lozinka korisnika
        /// </summary>
        [Required(ErrorMessage = "Lozinka je obavezna")]
        [MinLength(6, ErrorMessage = "Lozinka mora imati najmanje 6 karaktera")]
        string Password, 
        
        /// <summary>
        /// Zapamti me opcija
        /// </summary>
        bool RememberMe = false
    );
    
    /// <summary>
    /// Zahtjev za registraciju novog korisnika
    /// </summary>
    public record RegisterRequest(
        /// <summary>
        /// Email adresa korisnika
        /// </summary>
        [Required(ErrorMessage = "Email je obavezan")]
        [EmailAddress(ErrorMessage = "Neispravna email adresa")]
        string Email, 
        
        /// <summary>
        /// Lozinka korisnika
        /// </summary>
        [Required(ErrorMessage = "Lozinka je obavezna")]
        [MinLength(6, ErrorMessage = "Lozinka mora imati najmanje 6 karaktera")]
        string Password, 
        
        /// <summary>
        /// Ime korisnika
        /// </summary>
        [Required(ErrorMessage = "Ime je obavezno")]
        [MaxLength(50, ErrorMessage = "Ime ne može biti duže od 50 karaktera")]
        string FirstName, 
        
        /// <summary>
        /// Prezime korisnika
        /// </summary>
        [Required(ErrorMessage = "Prezime je obavezno")]
        [MaxLength(50, ErrorMessage = "Prezime ne može biti duže od 50 karaktera")]
        string LastName
    );
    
    /// <summary>
    /// Zahtjev za obnavljanje JWT tokena
    /// </summary>
    public record RefreshTokenRequest(
        /// <summary>
        /// Trenutni access token
        /// </summary>
        [Required(ErrorMessage = "Access token je obavezan")]
        string AccessToken, 
        
        /// <summary>
        /// Refresh token za obnavljanje
        /// </summary>
        [Required(ErrorMessage = "Refresh token je obavezan")]
        string RefreshToken
    );
    
    /// <summary>
    /// Odgovor sa JWT tokenima i informacijama o korisniku
    /// </summary>
    public record AuthResponse(
        /// <summary>
        /// JWT access token
        /// </summary>
        string AccessToken,
        
        /// <summary>
        /// Refresh token za obnavljanje access tokena
        /// </summary>
        string RefreshToken,
        
        /// <summary>
        /// Datum isteka access tokena
        /// </summary>
        DateTime ExpiresAt,
        
        /// <summary>
        /// Informacije o korisniku
        /// </summary>
        UserInfo User
    );
    
    /// <summary>
    /// Informacije o korisniku
    /// </summary>
    public record UserInfo(
        /// <summary>
        /// Jedinstveni identifikator korisnika
        /// </summary>
        string Id,
        
        /// <summary>
        /// Email adresa korisnika
        /// </summary>
        string Email,
        
        /// <summary>
        /// Ime korisnika
        /// </summary>
        string FirstName,
        
        /// <summary>
        /// Prezime korisnika
        /// </summary>
        string LastName,
        
        /// <summary>
        /// Da li je email potvrđen
        /// </summary>
        bool EmailConfirmed,

        /// <summary>
        /// Da li je organizator potvrđen od strane admina
        /// </summary>
        bool IsOrganizerVerified,
        
        /// <summary>
        /// Role korisnika
        /// </summary>
        string[] Roles
    );
    
    /// <summary>
    /// Odgovor za validaciju JWT tokena
    /// </summary>
    public record TokenValidationResponse(
        /// <summary>
        /// Da li je token valjan
        /// </summary>
        bool IsValid,
        
        /// <summary>
        /// ID korisnika
        /// </summary>
        string? UserId,
        
        /// <summary>
        /// Email korisnika
        /// </summary>
        string? Email,
        
        /// <summary>
        /// Role korisnika
        /// </summary>
        string[] Roles
    );
    
    /// <summary>
    /// Zahtjev za ponovno slanje email potvrde
    /// </summary>
    public record ResendConfirmationRequest(
        /// <summary>
        /// Email adresa korisnika
        /// </summary>
        [Required(ErrorMessage = "Email je obavezan")]
        [EmailAddress(ErrorMessage = "Neispravna email adresa")]
        string Email
    );
}
