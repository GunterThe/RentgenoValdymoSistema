using System.Security.Claims;
using System.Text.Encodings.Web;
using Microsoft.AspNetCore.Authentication;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Backend.Tests.Testing;

public sealed class TestAuthHandler : AuthenticationHandler<AuthenticationSchemeOptions>
{
    public const string SchemeName = "Test";

    public TestAuthHandler(
        IOptionsMonitor<AuthenticationSchemeOptions> options,
        ILoggerFactory logger,
        UrlEncoder encoder
    ) : base(options, logger, encoder)
    {
    }

    protected override Task<AuthenticateResult> HandleAuthenticateAsync()
    {

        var userId = Request.Headers.TryGetValue("X-Test-UserId", out var userIdHeader)
            && Guid.TryParse(userIdHeader.ToString(), out var parsed)
            ? parsed
            : Guid.Parse("11111111-1111-1111-1111-111111111111");

        var isAdmin = Request.Headers.TryGetValue("X-Test-Admin", out var adminHeader)
            && bool.TryParse(adminHeader.ToString(), out var adminValue)
            && adminValue;

        var isSuperAdmin = Request.Headers.TryGetValue("X-Test-SuperAdmin", out var superAdminHeader)
            && bool.TryParse(superAdminHeader.ToString(), out var superAdminValue)
            && superAdminValue;

        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, userId.ToString()),
            new("sub", userId.ToString()),
            new("admin", isAdmin ? bool.TrueString : bool.FalseString),
            new("superadmin", isSuperAdmin ? bool.TrueString : bool.FalseString),
        };

        var identity = new ClaimsIdentity(claims, SchemeName);
        var principal = new ClaimsPrincipal(identity);
        var ticket = new AuthenticationTicket(principal, SchemeName);
        return Task.FromResult(AuthenticateResult.Success(ticket));
    }
}
