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

            const string adminEmail = "amar.omerovic0607@gmail.com";
            const string adminPassword = "Password123!";
            
            try
            {
                // Provjeri da li Admin rola postoji
                if (!await roleManager.RoleExistsAsync("Admin"))
                {
                    logger.LogWarning("Admin rola ne postoji");
                    return;
                }

                // Provjeri da li admin korisnik već postoji
                var adminUser = await userManager.FindByEmailAsync(adminEmail);
                
                if (adminUser == null)
                {
                    // Kreiraj novog admin korisnika
                    adminUser = new ApplicationUser
                    {
                        UserName = adminEmail,
                        Email = adminEmail,
                        EmailConfirmed = true,
                        FirstName = "Admin",
                        LastName = "User",
                        CreatedAt = DateTime.UtcNow
                    };

                    var createResult = await userManager.CreateAsync(adminUser, adminPassword);
                    if (!createResult.Succeeded)
                    {
                        logger.LogError("Greška pri kreiranju admin korisnika: {Errors}", 
                            string.Join(", ", createResult.Errors.Select(e => e.Description)));
                        return;
                    }

                    logger.LogInformation("Admin korisnik {Email} je kreiran", adminEmail);
                }

                // Ažuriraj password ako je potrebno (za slučaj da korisnik već postoji)
                var passwordToken = await userManager.GeneratePasswordResetTokenAsync(adminUser);
                var passwordResult = await userManager.ResetPasswordAsync(adminUser, passwordToken, adminPassword);
                if (passwordResult.Succeeded)
                {
                    logger.LogInformation("Password za admin korisnika {Email} je ažuriran", adminEmail);
                }
                else
                {
                    logger.LogWarning("Nije moguće ažurirati password za {Email}: {Errors}", 
                        adminEmail, string.Join(", ", passwordResult.Errors.Select(e => e.Description)));
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
