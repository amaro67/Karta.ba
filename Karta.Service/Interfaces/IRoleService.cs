using Karta.Service.DTO;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace Karta.Service.Interfaces
{
    /// <summary>
    /// Interface za upravljanje rolama
    /// </summary>
    public interface IRoleService
    {
        /// <summary>
        /// Kreira novu rolu
        /// </summary>
        /// <param name="request">Podaci za kreiranje role</param>
        /// <returns>Kreiranu rolu</returns>
        Task<RoleResponse> CreateRoleAsync(CreateRoleRequest request);

        /// <summary>
        /// Ažurira postojeću rolu
        /// </summary>
        /// <param name="request">Podaci za ažuriranje role</param>
        /// <returns>Ažuriranu rolu</returns>
        Task<RoleResponse> UpdateRoleAsync(UpdateRoleRequest request);

        /// <summary>
        /// Briše rolu
        /// </summary>
        /// <param name="roleId">ID role za brisanje</param>
        /// <returns>True ako je uspješno obrisana</returns>
        Task<bool> DeleteRoleAsync(string roleId);

        /// <summary>
        /// Dohvata rolu po ID-u
        /// </summary>
        /// <param name="roleId">ID role</param>
        /// <returns>Rolu ili null ako ne postoji</returns>
        Task<RoleResponse?> GetRoleByIdAsync(string roleId);

        /// <summary>
        /// Dohvata rolu po nazivu
        /// </summary>
        /// <param name="roleName">Naziv role</param>
        /// <returns>Rolu ili null ako ne postoji</returns>
        Task<RoleResponse?> GetRoleByNameAsync(string roleName);

        /// <summary>
        /// Dohvata sve role
        /// </summary>
        /// <returns>Listu svih rola</returns>
        Task<List<RoleResponse>> GetAllRolesAsync();

        /// <summary>
        /// Dodaje rolu korisniku
        /// </summary>
        /// <param name="request">Podaci za dodavanje role</param>
        /// <returns>True ako je uspješno dodana</returns>
        Task<bool> AddUserToRoleAsync(AddUserToRoleRequest request);

        /// <summary>
        /// Uklanja rolu od korisnika
        /// </summary>
        /// <param name="request">Podaci za uklanjanje role</param>
        /// <returns>True ako je uspješno uklonjena</returns>
        Task<bool> RemoveUserFromRoleAsync(RemoveUserFromRoleRequest request);

        /// <summary>
        /// Dohvata sve korisnike sa određenom rolom
        /// </summary>
        /// <param name="roleName">Naziv role</param>
        /// <returns>Listu korisnika sa tom rolom</returns>
        Task<UsersInRoleResponse> GetUsersInRoleAsync(string roleName);

        /// <summary>
        /// Dohvata sve role korisnika
        /// </summary>
        /// <param name="userId">ID korisnika</param>
        /// <returns>Listu rola korisnika</returns>
        Task<List<RoleResponse>> GetUserRolesAsync(string userId);

        /// <summary>
        /// Provjerava da li korisnik ima određenu rolu
        /// </summary>
        /// <param name="userId">ID korisnika</param>
        /// <param name="roleName">Naziv role</param>
        /// <returns>True ako korisnik ima tu rolu</returns>
        Task<bool> IsUserInRoleAsync(string userId, string roleName);
    }
}
