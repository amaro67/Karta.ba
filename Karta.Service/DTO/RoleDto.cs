using System.ComponentModel.DataAnnotations;
using System;
using System.Collections.Generic;

namespace Karta.Service.DTO
{
    /// <summary>
    /// DTO za kreiranje nove role
    /// </summary>
    public record CreateRoleRequest
    {
        /// <summary>
        /// Naziv role
        /// </summary>
        [Required(ErrorMessage = "Naziv role je obavezan")]
        [StringLength(50, MinimumLength = 2, ErrorMessage = "Naziv role mora biti između 2 i 50 karaktera")]
        public string Name { get; init; } = string.Empty;

        /// <summary>
        /// Opis role
        /// </summary>
        [StringLength(200, ErrorMessage = "Opis role ne može biti duži od 200 karaktera")]
        public string? Description { get; init; }
    }

    /// <summary>
    /// DTO za ažuriranje role
    /// </summary>
    public record UpdateRoleRequest
    {
        /// <summary>
        /// ID role
        /// </summary>
        [Required(ErrorMessage = "ID role je obavezan")]
        public string Id { get; init; } = string.Empty;

        /// <summary>
        /// Naziv role
        /// </summary>
        [Required(ErrorMessage = "Naziv role je obavezan")]
        [StringLength(50, MinimumLength = 2, ErrorMessage = "Naziv role mora biti između 2 i 50 karaktera")]
        public string Name { get; init; } = string.Empty;

        /// <summary>
        /// Opis role
        /// </summary>
        [StringLength(200, ErrorMessage = "Opis role ne može biti duži od 200 karaktera")]
        public string? Description { get; init; }
    }

    /// <summary>
    /// DTO za response role
    /// </summary>
    public record RoleResponse
    {
        /// <summary>
        /// ID role
        /// </summary>
        public string Id { get; init; } = string.Empty;

        /// <summary>
        /// Naziv role
        /// </summary>
        public string Name { get; init; } = string.Empty;

        /// <summary>
        /// Normalizirani naziv role
        /// </summary>
        public string NormalizedName { get; init; } = string.Empty;

        /// <summary>
        /// Opis role
        /// </summary>
        public string? Description { get; init; }

        /// <summary>
        /// Datum kreiranja
        /// </summary>
        public DateTime CreatedAt { get; init; }

        /// <summary>
        /// Broj korisnika sa ovom rolom
        /// </summary>
        public int UserCount { get; init; }
    }

    /// <summary>
    /// DTO za dodavanje role korisniku
    /// </summary>
    public record AddUserToRoleRequest
    {
        /// <summary>
        /// ID korisnika
        /// </summary>
        [Required(ErrorMessage = "ID korisnika je obavezan")]
        public string UserId { get; init; } = string.Empty;

        /// <summary>
        /// Naziv role
        /// </summary>
        [Required(ErrorMessage = "Naziv role je obavezan")]
        public string RoleName { get; init; } = string.Empty;
    }

    /// <summary>
    /// DTO za uklanjanje role od korisnika
    /// </summary>
    public record RemoveUserFromRoleRequest
    {
        /// <summary>
        /// ID korisnika
        /// </summary>
        [Required(ErrorMessage = "ID korisnika je obavezan")]
        public string UserId { get; init; } = string.Empty;

        /// <summary>
        /// Naziv role
        /// </summary>
        [Required(ErrorMessage = "Naziv role je obavezan")]
        public string RoleName { get; init; } = string.Empty;
    }

    /// <summary>
    /// DTO za listu korisnika sa određenom rolom
    /// </summary>
    public record UsersInRoleResponse
    {
        /// <summary>
        /// Naziv role
        /// </summary>
        public string RoleName { get; init; } = string.Empty;

        /// <summary>
        /// Lista korisnika
        /// </summary>
        public List<UserInfo> Users { get; init; } = new();

        /// <summary>
        /// Ukupan broj korisnika
        /// </summary>
        public int TotalCount { get; init; }
    }
}
