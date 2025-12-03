using Karta.Model;
using Karta.Model.Entities;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
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

        public static async Task SeedAllData(IServiceProvider serviceProvider)
        {
            var context = serviceProvider.GetRequiredService<ApplicationDbContext>();
            var userManager = serviceProvider.GetRequiredService<UserManager<ApplicationUser>>();
            var roleManager = serviceProvider.GetRequiredService<RoleManager<ApplicationRole>>();
            var logger = serviceProvider.GetRequiredService<ILogger<SeedDataService>>();

            try
            {
                logger.LogInformation("Počinje seed-ovanje podataka...");

                // Provjeri da li već postoje podaci
                if (await context.Events.AnyAsync())
                {
                    logger.LogWarning("Baza već sadrži podatke. Preskačem seed-ovanje.");
                    return;
                }

                // 1. Kreiraj korisnike
                logger.LogInformation("Kreiranje korisnika...");
                var users = await CreateUsersAsync(userManager, roleManager, logger);
                logger.LogInformation($"Kreirano {users.Count} korisnika.");

                // 2. Kreiraj događaje
                logger.LogInformation("Kreiranje događaja...");
                var organizers = users.Where(u => userManager.IsInRoleAsync(u, "Organizer").Result).ToList();
                var events = await CreateEventsAsync(context, organizers, logger);
                logger.LogInformation($"Kreirano {events.Count} događaja.");

                // 3. Kreiraj PriceTier-e za svaki događaj
                logger.LogInformation("Kreiranje PriceTier-ova...");
                var priceTiers = await CreatePriceTiersAsync(context, events, logger);
                logger.LogInformation($"Kreirano {priceTiers.Count} PriceTier-ova.");

                // 4. Kreiraj narudžbe
                logger.LogInformation("Kreiranje narudžbi...");
                var regularUsers = users.Where(u => userManager.IsInRoleAsync(u, "User").Result).ToList();
                var orders = await CreateOrdersAsync(context, regularUsers, events, priceTiers, logger);
                logger.LogInformation($"Kreirano {orders.Count} narudžbi.");

                // 5. Kreiraj OrderItem-e
                logger.LogInformation("Kreiranje OrderItem-ova...");
                var orderItems = await CreateOrderItemsAsync(context, orders, events, priceTiers, logger);
                logger.LogInformation($"Kreirano {orderItems.Count} OrderItem-ova.");

                // 6. Kreiraj Ticket-e
                logger.LogInformation("Kreiranje Ticket-ova...");
                var tickets = await CreateTicketsAsync(context, orderItems, logger);
                logger.LogInformation($"Kreirano {tickets.Count} Ticket-ova.");

                // 7. Kreiraj ScanLog-ove
                logger.LogInformation("Kreiranje ScanLog-ova...");
                var scanLogs = await CreateScanLogsAsync(context, tickets, orderItems, logger);
                logger.LogInformation($"Kreirano {scanLogs.Count} ScanLog-ova.");

                // 8. Kreiraj EventScannerAssignment-e
                logger.LogInformation("Kreiranje EventScannerAssignment-ova...");
                var scanners = users.Where(u => userManager.IsInRoleAsync(u, "Scanner").Result).ToList();
                var assignments = await CreateEventScannerAssignmentsAsync(context, events, scanners, logger);
                logger.LogInformation($"Kreirano {assignments.Count} EventScannerAssignment-ova.");

                await context.SaveChangesAsync();
                logger.LogInformation("Seed-ovanje podataka uspješno završeno!");
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Greška pri seed-ovanju podataka");
                throw;
            }
        }

        private static async Task<List<ApplicationUser>> CreateUsersAsync(
            UserManager<ApplicationUser> userManager,
            RoleManager<ApplicationRole> roleManager,
            ILogger<SeedDataService> logger)
        {
            var users = new List<ApplicationUser>();
            var password = "Password123!";

            // Kreiraj 4 Organizatora
            for (int i = 1; i <= 4; i++)
            {
                var user = new ApplicationUser
                {
                    UserName = $"organizer{i}@karta.ba",
                    Email = $"organizer{i}@karta.ba",
                    EmailConfirmed = true,
                    FirstName = $"Organizator{i}",
                    LastName = "Test",
                    CreatedAt = DateTime.UtcNow.AddDays(-i * 10),
                    IsOrganizerVerified = i <= 2 // Prva 2 su verificirana
                };

                var result = await userManager.CreateAsync(user, password);
                if (result.Succeeded)
                {
                    await userManager.AddToRoleAsync(user, "Organizer");
                    users.Add(user);
                    logger.LogInformation($"Kreiran organizator: {user.Email}");
                }
            }

            // Kreiraj 3 Scanner-a
            for (int i = 1; i <= 3; i++)
            {
                var user = new ApplicationUser
                {
                    UserName = $"scanner{i}@karta.ba",
                    Email = $"scanner{i}@karta.ba",
                    EmailConfirmed = true,
                    FirstName = $"Scanner{i}",
                    LastName = "Test",
                    CreatedAt = DateTime.UtcNow.AddDays(-i * 5)
                };

                var result = await userManager.CreateAsync(user, password);
                if (result.Succeeded)
                {
                    await userManager.AddToRoleAsync(user, "Scanner");
                    users.Add(user);
                    logger.LogInformation($"Kreiran scanner: {user.Email}");
                }
            }

            // Kreiraj 10 User-a
            for (int i = 1; i <= 10; i++)
            {
                var user = new ApplicationUser
                {
                    UserName = $"user{i}@karta.ba",
                    Email = $"user{i}@karta.ba",
                    EmailConfirmed = true,
                    FirstName = $"User{i}",
                    LastName = "Test",
                    CreatedAt = DateTime.UtcNow.AddDays(-i * 3)
                };

                var result = await userManager.CreateAsync(user, password);
                if (result.Succeeded)
                {
                    await userManager.AddToRoleAsync(user, "User");
                    users.Add(user);
                    logger.LogInformation($"Kreiran korisnik: {user.Email}");
                }
            }

            return users;
        }

        private static async Task<List<Event>> CreateEventsAsync(
            ApplicationDbContext context,
            List<ApplicationUser> organizers,
            ILogger<SeedDataService> logger)
        {
            var events = new List<Event>();
            var categories = new[] { "Muzika", "Sport", "Kultura", "Tehnologija", "Edukacija", "Zabava", "Biznis", "Umjetnost" };
            var cities = new[] { "Sarajevo", "Banja Luka", "Mostar", "Tuzla", "Zenica", "Bihać", "Brčko", "Trebinje" };
            var statuses = new[] { "Published", "Draft", "Archived", "Cancelled" };

            var eventTitles = new[]
            {
                "Rock Koncert 2024", "Fudbalska Utakmica", "Jazz Festival", "Tech Conference",
                "Kazališna Predstava", "Koncert Narodne Muzike", "Basketball Turnir", "Film Festival",
                "Kulinarski Festival", "Književni Večer"
            };

            for (int i = 0; i < 10; i++)
            {
                var organizer = organizers[i % organizers.Count];
                var startsAt = DateTimeOffset.UtcNow.AddDays(30 + i * 7);
                var endsAt = startsAt.AddHours(3);

                var eventEntity = new Event
                {
                    Id = Guid.NewGuid(),
                    Title = eventTitles[i],
                    Slug = GenerateSlug(eventTitles[i], i),
                    Description = $"Opis događaja {i + 1}. Ovo je detaljan opis događaja koji se održava u {cities[i % cities.Length]}.",
                    Venue = $"Dvorana {i + 1}",
                    City = cities[i % cities.Length],
                    Country = "Bosna i Hercegovina",
                    StartsAt = startsAt,
                    EndsAt = endsAt,
                    Category = categories[i % categories.Length],
                    Tags = $"{categories[i % categories.Length]}, {cities[i % cities.Length]}",
                    Status = i < 6 ? "Published" : (i < 8 ? "Draft" : statuses[i % statuses.Length]),
                    CoverImageUrl = $"https://example.com/images/event{i + 1}.jpg",
                    CreatedAt = DateTime.UtcNow.AddDays(-(10 - i)),
                    CreatedBy = organizer.Id
                };

                events.Add(eventEntity);
            }

            context.Events.AddRange(events);
            await context.SaveChangesAsync();

            return events;
        }

        private static string GenerateSlug(string title, int index)
        {
            var slug = title.ToLower()
                .Replace(" ", "-")
                .Replace("č", "c")
                .Replace("ć", "c")
                .Replace("đ", "d")
                .Replace("š", "s")
                .Replace("ž", "z");
            return $"{slug}-{index + 1}";
        }

        private static async Task<List<PriceTier>> CreatePriceTiersAsync(
            ApplicationDbContext context,
            List<Event> events,
            ILogger<SeedDataService> logger)
        {
            var priceTiers = new List<PriceTier>();
            var tierNames = new[] { "Regular", "VIP", "Premium", "Early Bird" };

            foreach (var eventEntity in events)
            {
                // Kreiraj 2-3 PriceTier-a za svaki događaj
                var tierCount = 2 + (eventEntity.Id.GetHashCode() % 2); // 2 ili 3

                for (int i = 0; i < tierCount; i++)
                {
                    var capacity = 100 + (i * 50);
                    var price = 20.00m + (i * 15.00m);

                    var priceTier = new PriceTier
                    {
                        Id = Guid.NewGuid(),
                        EventId = eventEntity.Id,
                        Name = tierNames[i % tierNames.Length],
                        Price = price,
                        Currency = "BAM",
                        Capacity = capacity,
                        Sold = 0 // Početno stanje
                    };

                    priceTiers.Add(priceTier);
                }
            }

            context.PriceTiers.AddRange(priceTiers);
            await context.SaveChangesAsync();

            return priceTiers;
        }

        private static async Task<List<Order>> CreateOrdersAsync(
            ApplicationDbContext context,
            List<ApplicationUser> users,
            List<Event> events,
            List<PriceTier> priceTiers,
            ILogger<SeedDataService> logger)
        {
            var orders = new List<Order>();
            var statuses = new[] { "Paid", "Pending", "Failed", "Expired", "Cancelled" };

            for (int i = 0; i < 10; i++)
            {
                var user = users[i % users.Count];
                var status = i < 7 ? "Paid" : statuses[i % statuses.Length];
                var totalAmount = 0m; // Bit će izračunato nakon OrderItem-ova

                var order = new Order
                {
                    Id = Guid.NewGuid(),
                    UserId = user.Id,
                    TotalAmount = totalAmount, // Ažuriraćemo kasnije
                    Currency = "BAM",
                    Status = status,
                    StripePaymentIntentId = status == "Paid" ? $"pi_test_{i + 1}" : null,
                    CreatedAt = DateTime.UtcNow.AddDays(-(10 - i))
                };

                orders.Add(order);
            }

            context.Orders.AddRange(orders);
            await context.SaveChangesAsync();

            return orders;
        }

        private static async Task<List<OrderItem>> CreateOrderItemsAsync(
            ApplicationDbContext context,
            List<Order> orders,
            List<Event> events,
            List<PriceTier> priceTiers,
            ILogger<SeedDataService> logger)
        {
            var orderItems = new List<OrderItem>();
            var random = new Random();

            foreach (var order in orders)
            {
                // Svaka narudžba ima 1-3 OrderItem-a
                var itemCount = 1 + (order.Id.GetHashCode() % 3);

                for (int i = 0; i < itemCount; i++)
                {
                    var eventEntity = events[random.Next(events.Count)];
                    var eventPriceTiers = priceTiers.Where(pt => pt.EventId == eventEntity.Id).ToList();
                    
                    if (!eventPriceTiers.Any()) continue;

                    var priceTier = eventPriceTiers[random.Next(eventPriceTiers.Count)];
                    var qty = 1 + (random.Next(3)); // 1-3 karte

                    var orderItem = new OrderItem
                    {
                        Id = Guid.NewGuid(),
                        OrderId = order.Id,
                        EventId = eventEntity.Id,
                        PriceTierId = priceTier.Id,
                        Qty = qty,
                        UnitPrice = priceTier.Price
                    };

                    orderItems.Add(orderItem);

                    // Ažuriraj TotalAmount narudžbe
                    order.TotalAmount += priceTier.Price * qty;

                    // Ažuriraj Sold za PriceTier
                    priceTier.Sold += qty;
                }
            }

            context.OrderItems.AddRange(orderItems);
            
            // Ažuriraj Order.TotalAmount i PriceTier.Sold u bazi
            context.Orders.UpdateRange(orders);
            context.PriceTiers.UpdateRange(priceTiers);
            
            await context.SaveChangesAsync();

            return orderItems;
        }

        private static async Task<List<Ticket>> CreateTicketsAsync(
            ApplicationDbContext context,
            List<OrderItem> orderItems,
            ILogger<SeedDataService> logger)
        {
            var tickets = new List<Ticket>();

            foreach (var orderItem in orderItems)
            {
                // Kreiraj Ticket za svaki Qty u OrderItem-u
                for (int i = 0; i < orderItem.Qty; i++)
                {
                    // Ticket status: "Valid", "Used", "Refunded"
                    string status;
                    DateTime? usedAt = null;

                    if (orderItem.Order.Status == "Paid")
                    {
                        // Većina je "Valid", neki "Used", rijetko "Refunded"
                        if (i % 15 == 0)
                            status = "Refunded";
                        else if (i % 10 == 0)
                        {
                            status = "Used";
                            usedAt = orderItem.Order.CreatedAt.AddDays(1);
                        }
                        else
                            status = "Valid";
                    }
                    else if (orderItem.Order.Status == "Cancelled")
                    {
                        status = "Refunded";
                    }
                    else
                    {
                        // Za Pending, Failed, Expired - ticket je još "Valid" dok čeka plaćanje
                        status = "Valid";
                    }

                    var ticket = new Ticket
                    {
                        Id = Guid.NewGuid(),
                        OrderItemId = orderItem.Id,
                        TicketCode = Guid.NewGuid().ToString("N")[..32],
                        QRNonce = Guid.NewGuid().ToString("N")[..32],
                        Status = status,
                        IssuedAt = orderItem.Order.CreatedAt,
                        UsedAt = usedAt
                    };

                    tickets.Add(ticket);
                }
            }

            context.Tickets.AddRange(tickets);
            await context.SaveChangesAsync();

            return tickets;
        }

        private static async Task<List<ScanLog>> CreateScanLogsAsync(
            ApplicationDbContext context,
            List<Ticket> tickets,
            List<OrderItem> orderItems,
            ILogger<SeedDataService> logger)
        {
            var scanLogs = new List<ScanLog>();
            // Kreiraj ScanLog-ove za Used i Valid ticket-e
            var ticketsToScan = tickets.Where(t => t.Status == "Used" || t.Status == "Valid").Take(25).ToList();
            var gates = new[] { "A1", "A2", "B1", "B2", "C1", "C2" };
            var random = new Random();

            // Kreiraj lookup dictionary za brzi pristup Order status-u
            var orderItemLookup = orderItems.ToDictionary(oi => oi.Id, oi => oi.Order.Status);

            foreach (var ticket in ticketsToScan)
            {
                // ScanLog Result može biti: "Valid", "Invalid", "AlreadyUsed", "Unpaid"
                string result;
                
                if (ticket.Status == "Used")
                {
                    // Za Used ticket-e:
                    // - Prvi sken je "Valid" (kada je prvi put skeniran i označen kao Used)
                    // - Drugi sken je "AlreadyUsed" (kada se pokušava ponovo skenirati)
                    // Simuliramo da većina ima "Valid" (prvi sken), a neki "AlreadyUsed" (ponovni pokušaj)
                    result = random.Next(10) < 7 ? "Valid" : "AlreadyUsed";
                }
                else if (ticket.Status == "Valid")
                {
                    // Za Valid ticket-e:
                    // - Ako je order Paid, sken je "Valid"
                    // - Ako order nije Paid, sken je "Unpaid"
                    if (orderItemLookup.TryGetValue(ticket.OrderItemId, out var orderStatus) && orderStatus == "Paid")
                    {
                        result = "Valid";
                    }
                    else
                    {
                        result = "Unpaid";
                    }
                }
                else
                {
                    result = "Valid";
                }

                var scanLog = new ScanLog
                {
                    Id = Guid.NewGuid(),
                    TicketId = ticket.Id,
                    GateId = gates[random.Next(gates.Length)],
                    ScannedAt = ticket.UsedAt ?? ticket.IssuedAt.AddDays(1),
                    Result = result
                };

                scanLogs.Add(scanLog);
            }

            // Napomena: Ne možemo kreirati ScanLog sa TicketId = Guid.Empty zbog foreign key constraint-a
            // U stvarnosti, TicketService pokušava kreirati ScanLog sa Guid.Empty za invalid scan-ove,
            // ali to će baciti grešku. Za seed podatke, koristimo samo validne Ticket ID-jeve.

            context.ScanLogs.AddRange(scanLogs);
            await context.SaveChangesAsync();

            return scanLogs;
        }

        private static async Task<List<EventScannerAssignment>> CreateEventScannerAssignmentsAsync(
            ApplicationDbContext context,
            List<Event> events,
            List<ApplicationUser> scanners,
            ILogger<SeedDataService> logger)
        {
            var assignments = new List<EventScannerAssignment>();
            var usedCombinations = new HashSet<(Guid EventId, string ScannerUserId)>();

            // Dodijeli scanner-e na događaje, izbjegavajući duplikate
            for (int i = 0; i < events.Count && assignments.Count < events.Count; i++)
            {
                var eventEntity = events[i];
                var scanner = scanners[i % scanners.Count];
                var combination = (eventEntity.Id, scanner.Id);

                // Provjeri da li već postoji ova kombinacija (unique constraint)
                if (!usedCombinations.Contains(combination))
                {
                    var assignment = new EventScannerAssignment
                    {
                        Id = Guid.NewGuid(),
                        EventId = eventEntity.Id,
                        ScannerUserId = scanner.Id,
                        AssignedAt = DateTime.UtcNow.AddDays(-(10 - i))
                    };

                    assignments.Add(assignment);
                    usedCombinations.Add(combination);
                }
            }

            context.EventScannerAssignments.AddRange(assignments);
            await context.SaveChangesAsync();

            return assignments;
        }
    }
}
