using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Backend.Models;
using Backend.Tests.Testing;

namespace Backend.Tests.Controllers;

public sealed class AuthControllerTests : IClassFixture<CustomWebApplicationFactory>
{
    private readonly CustomWebApplicationFactory _factory;

    public AuthControllerTests(CustomWebApplicationFactory factory)
    {
        _factory = factory;
    }

    private sealed record AuthResponse(string AccessToken, string RefreshToken);

    [Fact]
    public async Task Login_Refresh_Revoke_Flow_Works()
    {
        await _factory.ResetDatabaseAsync();

        var user = new Naudotojas
        {
            Id = Guid.NewGuid(),
            Vardas = "V",
            Pavarde = "P",
            GimimoData = new DateTime(2000, 1, 1),
            Adminas = false,
            SuperAdminas = false,
            MustChangePassword = false,
            PrisijungimoId = "test-user",
            PasswordHash = BCrypt.Net.BCrypt.HashPassword("pass"),
        };

        await _factory.WithDbContextAsync(async db =>
        {
            db.Naudotojai.Add(user);
            await db.SaveChangesAsync();
        });

        var anon = _factory.CreateClient();

        var loginRes = await anon.PostAsJsonAsync("/api/Auth/login", new { prisijungimoId = "test-user", password = "pass" });
        Assert.Equal(HttpStatusCode.OK, loginRes.StatusCode);
        var login = await loginRes.Content.ReadFromJsonAsync<AuthResponse>();
        Assert.NotNull(login);
        Assert.False(string.IsNullOrWhiteSpace(login!.AccessToken));
        Assert.False(string.IsNullOrWhiteSpace(login.RefreshToken));

        var refreshRes = await anon.PostAsJsonAsync("/api/Auth/refresh", new { refreshToken = login.RefreshToken });
        Assert.Equal(HttpStatusCode.OK, refreshRes.StatusCode);
        var refreshed = await refreshRes.Content.ReadFromJsonAsync<AuthResponse>();
        Assert.NotNull(refreshed);
        Assert.False(string.IsNullOrWhiteSpace(refreshed!.AccessToken));
        Assert.False(string.IsNullOrWhiteSpace(refreshed.RefreshToken));
        Assert.NotEqual(login.RefreshToken, refreshed.RefreshToken);

        var authed = _factory.CreateClient().AsUser(user.Id);
        var revokeRes = await authed.PostAsJsonAsync("/api/Auth/revoke", new { refreshToken = refreshed.RefreshToken });
        Assert.Equal(HttpStatusCode.NoContent, revokeRes.StatusCode);

        var refreshAfterRevoke = await anon.PostAsJsonAsync("/api/Auth/refresh", new { refreshToken = refreshed.RefreshToken });
        Assert.Equal(HttpStatusCode.Unauthorized, refreshAfterRevoke.StatusCode);
    }

    [Fact]
    public async Task Token_Endpoint_Returns_Claims_When_Admin_And_Bearer_Provided()
    {
        await _factory.ResetDatabaseAsync();

        var user = new Naudotojas
        {
            Id = Guid.NewGuid(),
            Vardas = "A",
            Pavarde = "B",
            GimimoData = new DateTime(2001, 1, 1),
            Adminas = true,
            SuperAdminas = false,
            MustChangePassword = false,
            PrisijungimoId = "admin",
            PasswordHash = BCrypt.Net.BCrypt.HashPassword("pass"),
        };

        await _factory.WithDbContextAsync(async db =>
        {
            db.Naudotojai.Add(user);
            await db.SaveChangesAsync();
        });

        var anon = _factory.CreateClient();
        var loginRes = await anon.PostAsJsonAsync("/api/Auth/login", new { prisijungimoId = "admin", password = "pass" });
        Assert.Equal(HttpStatusCode.OK, loginRes.StatusCode);
        var login = await loginRes.Content.ReadFromJsonAsync<AuthResponse>();
        Assert.NotNull(login);

        var client = _factory.CreateClient().AsAdmin();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", login!.AccessToken);

        var tokenRes = await client.GetAsync("/api/Auth/token");
        Assert.Equal(HttpStatusCode.OK, tokenRes.StatusCode);

        using var doc = JsonDocument.Parse(await tokenRes.Content.ReadAsStringAsync());
        Assert.True(doc.RootElement.TryGetProperty("token", out _));
        Assert.True(doc.RootElement.TryGetProperty("claims", out _));
    }
}
