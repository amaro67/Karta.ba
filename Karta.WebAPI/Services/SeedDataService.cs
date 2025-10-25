using Karta.Model;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Logging;

namespace Karta.WebAPI.Services
{
    public class SeedDataService
    {
        public static async Task SeedAdminUser(IServiceProvider serviceProvider)
        {
            var userManager = serviceProvider.GetRequiredService<UserManager<ApplicationUser>>();
            var roleManager = serviceProvider.GetRequiredService<RoleManager<ApplicationRole>>();
            var logger = serviceProvider.GetRequiredService<ILogger<SeedDataService>>();

            // Specifični korisnik ID koji treba biti admin
            var adminUserId = "40594c39-078b-4107-94c9-079742cd52dd";
            
            try
            {
                // Provjeri da li korisnik postoji
                var adminUser = await userManager.FindByIdAsync(adminUserId);
                if (adminUser == null)
                {
                    logger.LogWarning("Admin korisnik sa ID {AdminUserId} nije pronađen", adminUserId);
                    return;
                }

                // Provjeri da li Admin rola postoji
                if (!await roleManager.RoleExistsAsync("Admin"))
                {
                    logger.LogWarning("Admin rola ne postoji");
                    return;
                }

                // Provjeri da li korisnik već ima Admin rolu
                if (await userManager.IsInRoleAsync(adminUser, "Admin"))
                {
                    logger.LogInformation("Korisnik {Email} već ima Admin rolu", adminUser.Email);
                    return;
                }

                // Dodijeli Admin rolu korisniku
                var result = await userManager.AddToRoleAsync(adminUser, "Admin");
                if (result.Succeeded)
                {
                    logger.LogInformation("Admin rola uspješno dodijeljena korisniku {Email}", adminUser.Email);
                }
                else
                {
                    logger.LogError("Greška pri dodjeljivanju Admin role korisniku {Email}: {Errors}", 
                        adminUser.Email, string.Join(", ", result.Errors.Select(e => e.Description)));
                }
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Greška pri seed-ovanju admin korisnika");
            }
        }
    }
}
