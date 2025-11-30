using Karta.Model;
using Karta.WebAPI.Services;
using Karta.WebAPI.Extensions;
using Karta.WebAPI.Filters;
using Karta.WebAPI.Authorization;
using Karta.WebAPI.Middleware;
using Karta.Service.Interfaces;
using Karta.Service.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Serilog;
using System.Text;
using System.Threading.RateLimiting;
using System.Linq;

var builder = WebApplication.CreateBuilder(args);

// Configure Serilog
Log.Logger = new LoggerConfiguration()
    .ReadFrom.Configuration(builder.Configuration)
    .Enrich.FromLogContext()
    .Enrich.WithMachineName()
    .Enrich.WithThreadId()
    .CreateLogger();

// Use Serilog for logging
builder.Host.UseSerilog();

// Add services to the container.

// Add Entity Framework
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
var isSQLServer = connectionString?.Contains("Server=") == true;

if (isSQLServer)
{
    builder.Services.AddDbContext<ApplicationDbContext>(options =>
        options.UseSqlServer(connectionString));
}
else
{
    builder.Services.AddDbContext<ApplicationDbContext>(options =>
        options.UseSqlite(connectionString));
}

// Add Identity
builder.Services.AddIdentity<ApplicationUser, ApplicationRole>(options =>
{
    // Password settings - Enhanced security
    options.Password.RequireDigit = true;
    options.Password.RequireLowercase = true;
    options.Password.RequireNonAlphanumeric = true;
    options.Password.RequireUppercase = true;
    options.Password.RequiredLength = 12; // Increased from 6 to 12
    options.Password.RequiredUniqueChars = 3; // Increased from 1 to 3

    // Lockout settings
    options.Lockout.DefaultLockoutTimeSpan = TimeSpan.FromMinutes(5);
    options.Lockout.MaxFailedAccessAttempts = 5;
    options.Lockout.AllowedForNewUsers = true;

    // User settings
    options.User.AllowedUserNameCharacters =
        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._@+";
    options.User.RequireUniqueEmail = true;
})
.AddEntityFrameworkStores<ApplicationDbContext>()
.AddDefaultTokenProviders();

// Add JWT Authentication
builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = builder.Configuration["Jwt:Issuer"],
        ValidAudience = builder.Configuration["Jwt:Audience"],
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"]!)),
        ClockSkew = TimeSpan.Zero
    };
});

// Add custom services
builder.Services.AddScoped<IEventService, EventService>();
builder.Services.AddScoped<IOrderService, OrderService>();
builder.Services.AddScoped<ITicketService, TicketService>();
builder.Services.AddScoped<IStripeService, StripeService>();
builder.Services.AddScoped<Karta.Service.Services.IEmailService, Karta.Service.Services.EmailService>();
builder.Services.AddScoped<IJwtService, JwtService>();
builder.Services.AddScoped<IRoleService, RoleService>();
builder.Services.AddScoped<IPasswordResetService, PasswordResetService>();
builder.Services.AddScoped<IScannerService, ScannerService>();

// Add RabbitMQ services only if enabled
var useRabbitMQ = builder.Configuration.GetValue<bool>("Email:UseRabbitMQ", false);
if (useRabbitMQ)
{
    builder.Services.AddSingleton<IRabbitMQService, RabbitMQService>();
}
else
{
    // Register a null implementation when RabbitMQ is disabled
    builder.Services.AddSingleton<IRabbitMQService>(provider => new NullRabbitMQService());
}

// Add security services
builder.Services.AddScoped<ValidationFilterAttribute>();

// Add rate limiting
builder.Services.AddRateLimiter(options =>
{
    options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(httpContext =>
        RateLimitPartition.GetFixedWindowLimiter(
            partitionKey: httpContext.User.Identity?.Name ?? httpContext.Request.Headers.Host.ToString(),
            factory: partition => new FixedWindowRateLimiterOptions
            {
                AutoReplenishment = true,
                PermitLimit = int.Parse(builder.Configuration["Security:RateLimitRequestsPerMinute"] ?? "100"),
                Window = TimeSpan.FromMinutes(1)
            }));
});

// Add background services
builder.Services.AddHostedService<Karta.WebAPI.Services.OrderCleanupService>();

// Add EmailConsumerService only if RabbitMQ is enabled
if (useRabbitMQ)
{
    builder.Services.AddHostedService<EmailConsumerService>();
}

// Add Authorization
builder.Services.AddAuthorization(options =>
{
    // Define permissions for each role
    var permissions = new[]
    {
        "ViewEvents", "PurchaseTickets", "ViewOwnOrders", "ViewOwnTickets", "GenerateQRCode",
        "CreateEvents", "EditOwnEvents", "DeleteOwnEvents", "ViewOwnEventOrders", "ViewOwnEventTickets",
        "ManageOwnEventPrices", "ManageOwnEventCapacity", "ViewOwnEventSales",
        "ScanTickets", "ValidateTickets", "ViewEventDetails",
        "ManageUsers", "ManageRoles", "ViewAllEvents", "ViewAllOrders", "ViewAllTickets",
        "ApproveOrganizers", "BlockUsers", "SystemSettings"
    };

    foreach (var permission in permissions)
    {
        options.AddPolicy($"Permission.{permission}", policy =>
            policy.Requirements.Add(new PermissionRequirement(permission)));
    }
});

// Add Permission Handler
builder.Services.AddScoped<IAuthorizationHandler, PermissionHandler>();

// Add CORS - Restricted configuration
var allowedOrigins = builder.Configuration["Security:CorsAllowedOrigins"]?.Split(',') ?? new[] { "https://localhost:3000", "http://localhost:3000", "http://localhost:57841" };

builder.Services.AddCors(options =>
{
    options.AddPolicy("RestrictedCors", policy =>
    {
        // Allow all localhost origins for development (Flutter web uses random ports)
        policy.SetIsOriginAllowed(origin =>
        {
            if (string.IsNullOrWhiteSpace(origin)) return false;
            
            // Allow localhost and 127.0.0.1 with any port
            var uri = new Uri(origin);
            return uri.Host == "localhost" || 
                   uri.Host == "127.0.0.1" || 
                   uri.Host == "::1" ||
                   allowedOrigins.Contains(origin);
        })
        .AllowAnyMethod()
        .AllowAnyHeader()
        .AllowCredentials();
    });
});

builder.Services.AddControllers();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new Microsoft.OpenApi.Models.OpenApiInfo
    {
        Title = "Karta.ba API",
        Version = "v1",
        Description = "API za online ticketing platformu Karta.ba",
        Contact = new Microsoft.OpenApi.Models.OpenApiContact
        {
            Name = "Karta.ba Support",
            Email = "support@karta.ba",
            Url = new Uri("https://karta.ba")
        },
        License = new Microsoft.OpenApi.Models.OpenApiLicense
        {
            Name = "MIT License",
            Url = new Uri("https://opensource.org/licenses/MIT")
        }
    });

    // Explicitly set OpenAPI version
    c.SwaggerGeneratorOptions.Servers.Clear();
    c.SwaggerGeneratorOptions.Servers.Add(new Microsoft.OpenApi.Models.OpenApiServer
    {
        Url = "/",
        Description = "Karta.ba API Server"
    });

    // Include XML comments
    var xmlFile = $"{System.Reflection.Assembly.GetExecutingAssembly().GetName().Name}.xml";
    var xmlPath = Path.Combine(AppContext.BaseDirectory, xmlFile);
    if (File.Exists(xmlPath))
    {
        c.IncludeXmlComments(xmlPath);
    }

    // Add JWT Authentication to Swagger
    c.AddSecurityDefinition("Bearer", new Microsoft.OpenApi.Models.OpenApiSecurityScheme
    {
        Description = "JWT Authorization header using the Bearer scheme. Example: \"Authorization: Bearer {token}\"",
        Name = "Authorization",
        In = Microsoft.OpenApi.Models.ParameterLocation.Header,
        Type = Microsoft.OpenApi.Models.SecuritySchemeType.ApiKey,
        Scheme = "Bearer"
    });

    c.AddSecurityRequirement(new Microsoft.OpenApi.Models.OpenApiSecurityRequirement
    {
        {
            new Microsoft.OpenApi.Models.OpenApiSecurityScheme
            {
                Reference = new Microsoft.OpenApi.Models.OpenApiReference
                {
                    Type = Microsoft.OpenApi.Models.ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });

    // Enable annotations
    c.EnableAnnotations();

    // Add error response schemas
    c.SchemaFilter<ErrorResponseSchemaFilter>();
});

var app = builder.Build();

// Configure the HTTP request pipeline.
// Enable Swagger in all environments for development
app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "Karta.ba API v1");
    c.RoutePrefix = "swagger";
    c.DocumentTitle = "Karta.ba API Documentation";
});

// Skip HTTPS redirection for webhook endpoint (Stripe CLI uses HTTP)
app.UseWhen(context => !context.Request.Path.StartsWithSegments("/api/order/webhook"), app =>
{
    app.UseHttpsRedirection();
});

// Add security headers middleware
app.UseMiddleware<SecurityHeadersMiddleware>();

// Add rate limiting
app.UseRateLimiter();

// Add CORS - Restricted (must be before UseAuthentication)
app.UseCors("RestrictedCors");

// Global exception handling middleware (mora biti prije Authentication/Authorization)
app.UseGlobalExceptionHandling();

// Add Authentication and Authorization
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

// Add a simple root endpoint for testing
app.MapGet("/", () => "Karta.ba API is running! Visit /swagger for API documentation.");

// Initialize database and roles
using (var scope = app.Services.CreateScope())
{
    var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
    context.Database.EnsureCreated();
    
    // Initialize core roles
    await RoleManagementService.InitializeCoreRoles(scope.ServiceProvider);
    
    // Seed admin user
    await SeedDataService.SeedAdminUser(scope.ServiceProvider);
}

try
{
    Log.Information("Starting Karta.ba Web API");
    app.Run();
}
catch (Exception ex)
{
    Log.Fatal(ex, "Application terminated unexpectedly");
}
finally
{
    Log.CloseAndFlush();
}

public partial class Program { }
