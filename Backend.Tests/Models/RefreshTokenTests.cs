using Backend.Models;

namespace Backend.Tests.Models;

public sealed class RefreshTokenTests
{
    [Fact]
    public void IsActive_Is_True_When_Not_Revoked_And_Not_Expired()
    {
        var token = new RefreshToken
        {
            Token = "t",
            Expires = DateTime.UtcNow.AddMinutes(5),
            Revoked = null,
            NaudotojasId = Guid.NewGuid(),
        };

        Assert.True(token.IsActive);
    }

    [Fact]
    public void IsActive_Is_False_When_Revoked()
    {
        var token = new RefreshToken
        {
            Token = "t",
            Expires = DateTime.UtcNow.AddMinutes(5),
            Revoked = DateTime.UtcNow,
            NaudotojasId = Guid.NewGuid(),
        };

        Assert.False(token.IsActive);
    }

    [Fact]
    public void IsActive_Is_False_When_Expired()
    {
        var token = new RefreshToken
        {
            Token = "t",
            Expires = DateTime.UtcNow.AddMinutes(-1),
            Revoked = null,
            NaudotojasId = Guid.NewGuid(),
        };

        Assert.False(token.IsActive);
    }
}
