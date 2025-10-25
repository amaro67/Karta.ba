using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using Karta.Model.Entities;

namespace Karta.Model
{
    public class ApplicationDbContext : IdentityDbContext<ApplicationUser, ApplicationRole, string>
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
            : base(options)
        {
        }

        // DbSets for custom entities
        public DbSet<Event> Events { get; set; }
        public DbSet<PriceTier> PriceTiers { get; set; }
        public DbSet<Order> Orders { get; set; }
        public DbSet<OrderItem> OrderItems { get; set; }
        public DbSet<Ticket> Tickets { get; set; }
        public DbSet<ScanLog> ScanLogs { get; set; }
        public DbSet<PasswordResetToken> PasswordResetTokens { get; set; }

        protected override void OnModelCreating(ModelBuilder builder)
        {
            base.OnModelCreating(builder);

            // Configure ApplicationUser properties
            builder.Entity<ApplicationUser>(entity =>
            {
                entity.Property(e => e.FirstName)
                    .HasMaxLength(50);

                entity.Property(e => e.LastName)
                    .HasMaxLength(50);

                entity.Property(e => e.CreatedAt)
                    .IsRequired();

                entity.Property(e => e.LastLoginAt);
            });

            // Configure ApplicationRole properties
            builder.Entity<ApplicationRole>(entity =>
            {
                entity.Property(e => e.Description)
                    .HasMaxLength(200);

                entity.Property(e => e.CreatedAt)
                    .IsRequired();
            });

            // Configure Event entity
            builder.Entity<Event>(entity =>
            {
                entity.HasKey(e => e.Id);
                
                entity.Property(e => e.Title)
                    .IsRequired()
                    .HasMaxLength(200);

                entity.Property(e => e.Slug)
                    .IsRequired()
                    .HasMaxLength(250);

                entity.Property(e => e.Description)
                    .HasMaxLength(2000);

                entity.Property(e => e.Venue)
                    .IsRequired()
                    .HasMaxLength(200);

                entity.Property(e => e.City)
                    .IsRequired()
                    .HasMaxLength(100);

                entity.Property(e => e.Country)
                    .IsRequired()
                    .HasMaxLength(100);

                entity.Property(e => e.Category)
                    .IsRequired()
                    .HasMaxLength(100);

                entity.Property(e => e.Tags)
                    .HasMaxLength(500);

                entity.Property(e => e.Status)
                    .IsRequired()
                    .HasMaxLength(50);

                entity.Property(e => e.CoverImageUrl)
                    .HasMaxLength(500);

                entity.Property(e => e.CreatedAt)
                    .IsRequired();

                // Indexes
                entity.HasIndex(e => e.Slug).IsUnique();
                entity.HasIndex(e => e.StartsAt);
                entity.HasIndex(e => e.City);
                entity.HasIndex(e => e.Category);
                entity.HasIndex(e => e.Status);
            });

            // Configure PriceTier entity
            builder.Entity<PriceTier>(entity =>
            {
                entity.HasKey(e => e.Id);
                
                entity.Property(e => e.Name)
                    .IsRequired()
                    .HasMaxLength(100);

                entity.Property(e => e.Price)
                    .HasColumnType("decimal(18,2)")
                    .IsRequired();

                entity.Property(e => e.Currency)
                    .IsRequired()
                    .HasMaxLength(3);

                // Indexes
                entity.HasIndex(e => e.EventId);
            });

            // Configure Order entity
            builder.Entity<Order>(entity =>
            {
                entity.HasKey(e => e.Id);
                
                entity.Property(e => e.UserId)
                    .IsRequired()
                    .HasMaxLength(450);

                entity.Property(e => e.TotalAmount)
                    .HasColumnType("decimal(18,2)")
                    .IsRequired();

                entity.Property(e => e.Currency)
                    .IsRequired()
                    .HasMaxLength(3);

                entity.Property(e => e.Status)
                    .IsRequired()
                    .HasMaxLength(50);

                entity.Property(e => e.StripePaymentIntentId)
                    .HasMaxLength(100);

                entity.Property(e => e.CreatedAt)
                    .IsRequired();

                // Indexes
                entity.HasIndex(e => e.UserId);
                entity.HasIndex(e => e.Status);
                entity.HasIndex(e => e.CreatedAt);
            });

            // Configure OrderItem entity
            builder.Entity<OrderItem>(entity =>
            {
                entity.HasKey(e => e.Id);
                
                entity.Property(e => e.UnitPrice)
                    .HasColumnType("decimal(18,2)")
                    .IsRequired();

                // Foreign key relationships
                entity.HasOne(e => e.Order)
                    .WithMany(e => e.Items)
                    .HasForeignKey(e => e.OrderId)
                    .OnDelete(DeleteBehavior.Cascade);

                // Indexes
                entity.HasIndex(e => e.OrderId);
                entity.HasIndex(e => e.EventId);
                entity.HasIndex(e => e.PriceTierId);
            });

            // Configure Ticket entity
            builder.Entity<Ticket>(entity =>
            {
                entity.HasKey(e => e.Id);
                
                entity.Property(e => e.TicketCode)
                    .IsRequired()
                    .HasMaxLength(32);

                entity.Property(e => e.QRNonce)
                    .IsRequired()
                    .HasMaxLength(32);

                entity.Property(e => e.Status)
                    .IsRequired()
                    .HasMaxLength(20);

                entity.Property(e => e.IssuedAt)
                    .IsRequired();

                // Foreign key relationship
                entity.HasOne(e => e.OrderItem)
                    .WithMany(e => e.Tickets)
                    .HasForeignKey(e => e.OrderItemId)
                    .OnDelete(DeleteBehavior.Cascade);

                // Indexes
                entity.HasIndex(e => e.OrderItemId);
                entity.HasIndex(e => e.TicketCode).IsUnique();
                entity.HasIndex(e => e.QRNonce).IsUnique();
                entity.HasIndex(e => e.Status);
            });

            // Configure ScanLog entity
            builder.Entity<ScanLog>(entity =>
            {
                entity.HasKey(e => e.Id);
                
                entity.Property(e => e.GateId)
                    .IsRequired()
                    .HasMaxLength(10);

                entity.Property(e => e.Result)
                    .IsRequired()
                    .HasMaxLength(20);

                entity.Property(e => e.ScannedAt)
                    .IsRequired();

                // Indexes
                entity.HasIndex(e => e.TicketId);
                entity.HasIndex(e => e.GateId);
                entity.HasIndex(e => e.ScannedAt);
            });

            // Configure PasswordResetToken
            builder.Entity<PasswordResetToken>(entity =>
            {
                entity.HasKey(e => e.Id);

                entity.Property(e => e.UserId)
                    .IsRequired()
                    .HasMaxLength(450);

                entity.Property(e => e.Token)
                    .IsRequired()
                    .HasMaxLength(500);

                entity.Property(e => e.ExpiresAt)
                    .IsRequired();

                entity.Property(e => e.IsUsed)
                    .IsRequired();

                entity.Property(e => e.CreatedAt)
                    .IsRequired();

                // Foreign key relationship
                entity.HasOne(e => e.User)
                    .WithMany()
                    .HasForeignKey(e => e.UserId)
                    .OnDelete(DeleteBehavior.Cascade);

                // Indexes
                entity.HasIndex(e => e.Token);
                entity.HasIndex(e => e.UserId);
                entity.HasIndex(e => e.ExpiresAt);
            });
        }
    }
}
