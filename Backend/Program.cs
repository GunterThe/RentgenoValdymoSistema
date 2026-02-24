using Backend.Data;
using Backend.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi;
using System.Text;
using Npgsql;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddEndpointsApiExplorer();

// Register controllers
builder.Services.AddControllers();

// Configure CORS for development and local frontend usage
builder.Services.AddCors(options =>
{
    options.AddPolicy(name: "AllowLocal",
        policy =>
        {
            policy.WithOrigins("http://localhost:8080", "http://127.0.0.1:8080")
                  .AllowAnyHeader()
                  .AllowAnyMethod()
                  .AllowCredentials();
        });
});
builder.Services.AddSwaggerGen(options =>
{
    // ...

    options.AddSecurityDefinition("bearer", new OpenApiSecurityScheme
    {
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        Description = "JWT Authorization header using the Bearer scheme."
    });

    options.AddSecurityRequirement(document => new OpenApiSecurityRequirement
    {
        [new OpenApiSecuritySchemeReference("bearer", document)] = []
    });
});
// Swagger/OpenAPI for controllers
builder.Services.AddEndpointsApiExplorer();
// Configure DbContext for PostgreSQL
var connectionString = builder.Configuration.GetConnectionString("Default")
                       ?? builder.Configuration["ConnectionStrings:Default"]
                       ?? Environment.GetEnvironmentVariable("CONNECTION_STRING");

if (string.IsNullOrWhiteSpace(connectionString))
{
    throw new InvalidOperationException("Connection string 'Default' not found. Set it in appsettings or environment variable 'CONNECTION_STRING'.");
}

builder.Services.AddDbContext<AppDbContext>(options =>
        options.UseNpgsql(connectionString,
        o => o.MapEnum<TestoTipas>("testotipas")));


builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("AdminOnly", policy =>
        policy.RequireClaim("admin", bool.TrueString));
});

builder.Services.Configure<JwtOptions>(builder.Configuration.GetSection("Jwt"));
builder.Services.AddScoped<ITokenService, TokenService>();

var jwtSection = builder.Configuration.GetSection("Jwt");
var key = Encoding.UTF8.GetBytes(jwtSection["Key"]!);

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
}).AddJwtBearer(options =>
{
    options.RequireHttpsMetadata = false; // consider true in production
    options.SaveToken = true;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidIssuer = jwtSection["Issuer"],
        ValidAudience = jwtSection["Audience"],
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(key),
        ClockSkew = TimeSpan.Zero
    };
});

var app = builder.Build();

static async Task ClearAllRefreshTokensAsync(IServiceProvider services, ILogger logger, CancellationToken ct = default)
{
    try
    {
        using var scope = services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        // Safe & provider-agnostic (works even if ExecuteDelete isn't available).
        var tokens = await db.RefreshTokens.ToListAsync(ct);
        if (tokens.Count == 0) return;

        db.RefreshTokens.RemoveRange(tokens);
        await db.SaveChangesAsync(ct);
        logger.LogInformation("Cleared {Count} refresh tokens.", tokens.Count);
    }
    catch (Exception ex)
    {
        // Best-effort: don't crash the app due to cleanup.
        logger.LogError(ex, "Failed to clear refresh tokens.");
    }
}

var clearOnStartup = app.Configuration.GetValue<bool>("AuthCleanup:ClearRefreshTokensOnStartup");
if (clearOnStartup)
{
    await ClearAllRefreshTokensAsync(app.Services, app.Logger);
}

var clearOnShutdown = app.Configuration.GetValue<bool>("AuthCleanup:ClearRefreshTokensOnShutdown");
if (clearOnShutdown)
{
    app.Lifetime.ApplicationStopping.Register(() =>
    {
        // ApplicationStopping doesn't support async callbacks; block briefly as best-effort.
        ClearAllRefreshTokensAsync(app.Services, app.Logger).GetAwaiter().GetResult();
    });
}

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

// Enable CORS (use the named policy)
app.UseCors("AllowLocal");

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();