using Backend.Data;
using Backend.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi;
using System.Text;
using Npgsql;
using System.Text.Json;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddEndpointsApiExplorer();

builder.Services.AddControllers();

if (builder.Environment.IsDevelopment())
{
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
}
builder.Services.AddSwaggerGen(options =>
{

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
builder.Services.AddEndpointsApiExplorer();
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
    options.AddPolicy("SuperAdminOnly", policy =>
        policy.RequireClaim("superadmin", bool.TrueString));
});

builder.Services.Configure<JwtOptions>(builder.Configuration.GetSection("Jwt"));
builder.Services.AddScoped<ITokenService, TokenService>();

var jwtSection = builder.Configuration.GetSection("Jwt");
var jwtKey = jwtSection["Key"];
var jwtIssuer = jwtSection["Issuer"];
var jwtAudience = jwtSection["Audience"];

if (string.IsNullOrWhiteSpace(jwtKey))
{
    throw new InvalidOperationException(
        "JWT key is missing. Set configuration 'Jwt:Key' (env var 'Jwt__Key') in Docker/Production.");
}
if (string.IsNullOrWhiteSpace(jwtIssuer) || string.IsNullOrWhiteSpace(jwtAudience))
{
    throw new InvalidOperationException(
        "JWT issuer/audience missing. Set 'Jwt:Issuer' and 'Jwt:Audience' (env vars 'Jwt__Issuer' and 'Jwt__Audience').");
}

var key = Encoding.UTF8.GetBytes(jwtKey);

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
}).AddJwtBearer(options =>
{
    options.RequireHttpsMetadata = false;
    options.SaveToken = true;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidIssuer = jwtIssuer,
        ValidAudience = jwtAudience,
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(key),
        ClockSkew = TimeSpan.Zero
    };
});

var app = builder.Build();

static async Task EnsureMustChangePasswordColumnAsync(IServiceProvider services, ILogger logger, CancellationToken ct = default)
{
    try
    {
        using var scope = services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        await db.Database.ExecuteSqlRawAsync(
            "ALTER TABLE public.naudotojas ADD COLUMN IF NOT EXISTS must_change_password boolean NOT NULL DEFAULT false;",
            ct
        );
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "Failed to ensure must_change_password column.");
    }
}

await EnsureMustChangePasswordColumnAsync(app.Services, app.Logger);

static async Task ClearAllRefreshTokensAsync(IServiceProvider services, ILogger logger, CancellationToken ct = default)
{
    try
    {
        using var scope = services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var tokens = await db.RefreshTokens.ToListAsync(ct);
        if (tokens.Count == 0) return;

        db.RefreshTokens.RemoveRange(tokens);
        await db.SaveChangesAsync(ct);
        logger.LogInformation("Cleared {Count} refresh tokens.", tokens.Count);
    }
    catch (Exception ex)
    {
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
        ClearAllRefreshTokensAsync(app.Services, app.Logger).GetAwaiter().GetResult();
    });
}

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

if (app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}

if (app.Environment.IsDevelopment())
{
    app.UseCors("AllowLocal");
}

app.UseStatusCodePages(async statusCodeContext =>
{
    var context = statusCodeContext.HttpContext;

    if (context.Response.StatusCode is StatusCodes.Status403Forbidden)
    {
        var endpoint = context.GetEndpoint();
        var authorizeData = endpoint?.Metadata.GetOrderedMetadata<IAuthorizeData>();
        var policyName = authorizeData?.FirstOrDefault(a => !string.IsNullOrWhiteSpace(a.Policy))?.Policy;

        var message = policyName switch
        {
            "AdminOnly" => "Šiam veiksmui reikia administratoriaus prieigos.",
            "SuperAdminOnly" => "Šiam veiksmui reikia superadministratoriaus prieigos.",
            _ => "Neturite teisių atlikti šį veiksmą."
        };

        context.Response.ContentType = "application/json; charset=utf-8";
        await context.Response.WriteAsync(JsonSerializer.Serialize(new { message }));
    }
});

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();