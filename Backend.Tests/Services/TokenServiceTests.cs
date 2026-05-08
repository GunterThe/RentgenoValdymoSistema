using System.IdentityModel.Tokens.Jwt;
using Backend.Models;
using Microsoft.Extensions.Options;

namespace Backend.Tests.Services;

public sealed class TokenServiceTests
{
    [Fact]
    public void CreateAccessToken_Contains_Expected_Claims_And_Metadata()
    {
        var options = Options.Create(new JwtOptions
        {
            Issuer = "issuer",
            Audience = "audience",
            Key = "THIS_IS_A_TEST_KEY_THAT_IS_LONG_ENOUGH_32+",
            AccessTokenMinutes = 5,
            RefreshTokenDays = 7,
        });

        var service = new TokenService(options);

        var user = new Naudotojas
        {
            Id = Guid.NewGuid(),
            Vardas = "Vardas",
            Pavarde = "Pavarde",
            PrisijungimoId = "user@example.com",
            Adminas = true,
            SuperAdminas = false,
            MustChangePassword = true,
            GimimoData = new DateTime(2000, 1, 1),
            PasswordHash = "hash",
        };

        var tokenString = service.CreateAccessToken(user);
        Assert.False(string.IsNullOrWhiteSpace(tokenString));

        var jwt = new JwtSecurityTokenHandler().ReadJwtToken(tokenString);

        Assert.Equal("issuer", jwt.Issuer);
        Assert.Contains(jwt.Audiences, a => a == "audience");

        var claims = jwt.Claims.ToDictionary(c => c.Type, c => c.Value);
        Assert.Equal(user.Id.ToString(), claims[JwtRegisteredClaimNames.Sub]);
        Assert.Equal(user.PrisijungimoId, claims[JwtRegisteredClaimNames.Email]);
        Assert.Equal(user.Vardas, claims["vardas"]);
        Assert.Equal(user.Pavarde, claims["pavarde"]);
        Assert.Equal(user.Adminas.ToString(), claims["admin"]);
        Assert.Equal(user.SuperAdminas.ToString(), claims["superadmin"]);
        Assert.Equal(user.MustChangePassword.ToString(), claims["mustChangePassword"]);

        var now = DateTime.UtcNow;
        Assert.True(jwt.ValidTo >= now.AddMinutes(4));
        Assert.True(jwt.ValidTo <= now.AddMinutes(6));
    }

    [Fact]
    public void CreateRefreshToken_Creates_Base64_Token_And_Sets_Expiry()
    {
        var options = Options.Create(new JwtOptions
        {
            Issuer = "issuer",
            Audience = "audience",
            Key = "THIS_IS_A_TEST_KEY_THAT_IS_LONG_ENOUGH_32+",
            AccessTokenMinutes = 5,
            RefreshTokenDays = 2,
        });

        var service = new TokenService(options);

        var user = new Naudotojas
        {
            Id = Guid.NewGuid(),
            Vardas = "V",
            Pavarde = "P",
            PrisijungimoId = "u",
            Adminas = false,
            SuperAdminas = false,
            MustChangePassword = false,
            GimimoData = new DateTime(2000, 1, 1),
            PasswordHash = "hash",
        };

        var refresh = service.CreateRefreshToken(user);

        Assert.NotNull(refresh);
        Assert.False(string.IsNullOrWhiteSpace(refresh.Token));
        Assert.Equal(user.Id, refresh.NaudotojasId);
        Assert.Same(user, refresh.Naudotojas);

        var decoded = Convert.FromBase64String(refresh.Token);
        Assert.Equal(64, decoded.Length);

        var now = DateTime.UtcNow;
        Assert.True(refresh.Expires >= now.AddDays(1));
        Assert.True(refresh.Expires <= now.AddDays(3));
    }

    [Fact]
    public void CreateAccessToken_Throws_When_User_Is_Null()
    {
        var options = Options.Create(new JwtOptions
        {
            Issuer = "issuer",
            Audience = "audience",
            Key = "THIS_IS_A_TEST_KEY_THAT_IS_LONG_ENOUGH_32+",
        });

        var service = new TokenService(options);

        Assert.ThrowsAny<Exception>(() => service.CreateAccessToken(null!));
    }
}
