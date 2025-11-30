using System;
using System.ComponentModel.DataAnnotations;

namespace Karta.Service.DTO
{
    /// <summary>
    /// Zahtjev za kreiranje korisnika od strane admina
    /// </summary>
    public record CreateUserRequest(
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
        [MinLength(12, ErrorMessage = "Lozinka mora imati najmanje 12 karaktera")]
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
        string LastName,
        
        /// <summary>
        /// Rola koja će biti dodijeljena korisniku
        /// </summary>
        string? RoleName = null
    );

    /// <summary>
    /// Zahtjev za ažuriranje korisnika
    /// </summary>
    public record UpdateUserRequest(
        /// <summary>
        /// Ime korisnika
        /// </summary>
        [MaxLength(50, ErrorMessage = "Ime ne može biti duže od 50 karaktera")]
        string? FirstName,
        
        /// <summary>
        /// Prezime korisnika
        /// </summary>
        [MaxLength(50, ErrorMessage = "Prezime ne može biti duže od 50 karaktera")]
        string? LastName,
        
        /// <summary>
        /// Email adresa korisnika (ignorira se - email se ne može mijenjati)
        /// </summary>
        [EmailAddress(ErrorMessage = "Neispravna email adresa")]
        string? Email,
        
        /// <summary>
        /// Da li je email potvrđen
        /// </summary>
        bool? EmailConfirmed
    );

    /// <summary>
    /// Zahtjev za postavljanje verifikacije organizatora
    /// </summary>
    /// <param name="IsVerified">Nova vrijednost verifikacije</param>
    public record OrganizerVerificationRequest(bool IsVerified);

    /// <summary>
    /// Detaljni odgovor sa informacijama o korisniku
    /// </summary>
    public record UserDetailResponse(
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
        /// Datum kreiranja korisnika
        /// </summary>
        DateTime CreatedAt,
        
        /// <summary>
        /// Datum posljednje prijave
        /// </summary>
        DateTime? LastLoginAt,
        
        /// <summary>
        /// Role korisnika
        /// </summary>
        string[] Roles
    );
}

