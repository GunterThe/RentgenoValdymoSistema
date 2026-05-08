using System.Net;
using System.Net.Http;
using System.Net.Http.Json;
using System.Text.Json;
using Backend.Controllers;
using Backend.Models;
using Backend.Tests.Testing;

namespace Backend.Tests.Controllers;

public sealed class NaudotojasControllerTests : IClassFixture<CustomWebApplicationFactory>
{
    private readonly CustomWebApplicationFactory _factory;

    public NaudotojasControllerTests(CustomWebApplicationFactory factory)
    {
        _factory = factory;
    }

    private async Task<(HttpClient client, NaudotojasController.NaudotojasListItem created)> CreateUserAsync()
    {
        await _factory.ResetDatabaseAsync();
        var client = _factory.CreateClient().AsAdmin();

        var createRes = await client.PostAsJsonAsync("/api/Naudotojas", new
        {
            vardas = "Jonas",
            pavarde = "Jonaitis",
            gimimoData = new DateTime(2000, 1, 1, 0, 0, 0, DateTimeKind.Utc),
            adminas = false,
            password = "secret1",
        });

        Assert.Equal(HttpStatusCode.Created, createRes.StatusCode);
        var created = await createRes.Content.ReadFromJsonAsync<NaudotojasController.NaudotojasListItem>();
        Assert.NotNull(created);
        Assert.NotEqual(Guid.Empty, created!.Id);
        return (client, created);
    }

    [Fact]
    public async Task Admin_Can_Create_User()
    {
        var (_, created) = await CreateUserAsync();
        Assert.Equal("Jonas", created.Vardas);
    }

    [Fact]
    public async Task Admin_Can_List_Users()
    {
        var (client, created) = await CreateUserAsync();

        var listRes = await client.GetAsync("/api/Naudotojas");
        Assert.Equal(HttpStatusCode.OK, listRes.StatusCode);
        var list = await listRes.Content.ReadFromJsonAsync<List<NaudotojasController.NaudotojasListItem>>();
        Assert.NotNull(list);
        Assert.Contains(list!, u => u.Id == created.Id);
    }

    [Fact]
    public async Task Admin_Can_Get_User_And_Sensitive_Fields_Are_Hidden()
    {
        var (client, created) = await CreateUserAsync();

        var getRes = await client.GetAsync($"/api/Naudotojas/{created.Id}");
        Assert.Equal(HttpStatusCode.OK, getRes.StatusCode);
        var fetched = await getRes.Content.ReadFromJsonAsync<Naudotojas>();
        Assert.NotNull(fetched);

        Assert.Equal(string.Empty, fetched!.PasswordHash);
        Assert.Equal(string.Empty, fetched.PrisijungimoId);
        Assert.False(fetched.Adminas);
    }

    [Fact]
    public async Task Admin_Can_Delete_User()
    {
        var (client, created) = await CreateUserAsync();

        var delRes = await client.DeleteAsync($"/api/Naudotojas/{created.Id}");
        Assert.Equal(HttpStatusCode.NoContent, delRes.StatusCode);

        var getRes2 = await client.GetAsync($"/api/Naudotojas/{created.Id}");
        Assert.Equal(HttpStatusCode.NotFound, getRes2.StatusCode);
    }

    [Fact]
    public async Task Admin_Can_Update_User()
    {
        await _factory.ResetDatabaseAsync();
        var client = _factory.CreateClient().AsAdmin();

        var user = new Naudotojas
        {
            Id = Guid.NewGuid(),
            Vardas = "A",
            Pavarde = "B",
            GimimoData = new DateTime(1999, 1, 1, 0, 0, 0, DateTimeKind.Utc),
            Adminas = false,
            PrisijungimoId = "a.b.123",
            PasswordHash = BCrypt.Net.BCrypt.HashPassword("secret1"),
            SuperAdminas = false,
            MustChangePassword = false,
        };

        await _factory.WithDbContextAsync(async db =>
        {
            db.Naudotojai.Add(user);
            await db.SaveChangesAsync();
        });

        var res = await client.PutAsJsonAsync($"/api/Naudotojas/{user.Id}", new
        {
            id = user.Id,
            vardas = "Updated",
            pavarde = user.Pavarde,
            gimimoData = user.GimimoData,
            adminas = user.Adminas,
            passwordHash = user.PasswordHash,
            prisijungimoId = user.PrisijungimoId,
            superAdminas = user.SuperAdminas,
            mustChangePassword = user.MustChangePassword,
            refreshToken = Array.Empty<object>(),
            zinutes = Array.Empty<object>(),
        });

        Assert.Equal(HttpStatusCode.NoContent, res.StatusCode);

        await _factory.WithDbContextAsync(async db =>
        {
            var updated = await db.Naudotojai.FindAsync(user.Id);
            Assert.NotNull(updated);
            Assert.Equal("Updated", updated!.Vardas);
        });
    }

    [Fact]
    public async Task Create_Returns_Forbidden_For_NonAdmin_And_Includes_AdminOnly_Message()
    {
        await _factory.ResetDatabaseAsync();

        var client = _factory.CreateClient().AsUser(Guid.NewGuid(), admin: false);
        var res = await client.PostAsJsonAsync("/api/Naudotojas", new
        {
            vardas = "Jonas",
            pavarde = "Jonaitis",
            gimimoData = new DateTime(2000, 1, 1),
            adminas = false,
            password = "secret1",
        });

        Assert.Equal(HttpStatusCode.Forbidden, res.StatusCode);
        using var doc = JsonDocument.Parse(await res.Content.ReadAsStringAsync());
        Assert.Equal("Šiam veiksmui reikia administratoriaus prieigos.", doc.RootElement.GetProperty("message").GetString());
    }

    [Fact]
    public async Task ToggleAdmin_Returns_Forbidden_For_Admin_Not_SuperAdmin_And_Includes_Message()
    {
        await _factory.ResetDatabaseAsync();

        var user = new Naudotojas
        {
            Id = Guid.NewGuid(),
            Vardas = "A",
            Pavarde = "B",
            GimimoData = new DateTime(1999, 1, 1, 0, 0, 0, DateTimeKind.Utc),
            Adminas = false,
            PrisijungimoId = "a.b.123",
            PasswordHash = BCrypt.Net.BCrypt.HashPassword("secret1"),
            SuperAdminas = false,
            MustChangePassword = false,
        };

        await _factory.WithDbContextAsync(async db =>
        {
            db.Naudotojai.Add(user);
            await db.SaveChangesAsync();
        });

        var client = _factory.CreateClient().AsUser(Guid.NewGuid(), admin: true, superAdmin: false);
        var res = await client.PutAsync($"/api/Naudotojas/toggleAdmin/{user.Id}", content: null);

        Assert.Equal(HttpStatusCode.Forbidden, res.StatusCode);
        using var doc = JsonDocument.Parse(await res.Content.ReadAsStringAsync());
        Assert.Equal("Šiam veiksmui reikia superadministratoriaus prieigos.", doc.RootElement.GetProperty("message").GetString());
    }

    [Fact]
    public async Task ToggleAdmin_Works_For_SuperAdmin()
    {
        await _factory.ResetDatabaseAsync();

        var user = new Naudotojas
        {
            Id = Guid.NewGuid(),
            Vardas = "A",
            Pavarde = "B",
            GimimoData = new DateTime(1999, 1, 1, 0, 0, 0, DateTimeKind.Utc),
            Adminas = false,
            PrisijungimoId = "a.b.123",
            PasswordHash = BCrypt.Net.BCrypt.HashPassword("secret1"),
            SuperAdminas = false,
            MustChangePassword = false,
        };

        await _factory.WithDbContextAsync(async db =>
        {
            db.Naudotojai.Add(user);
            await db.SaveChangesAsync();
        });

        var client = _factory.CreateClient().AsSuperAdmin();
        var res = await client.PutAsync($"/api/Naudotojas/toggleAdmin/{user.Id}", content: null);
        Assert.Equal(HttpStatusCode.NoContent, res.StatusCode);

        await _factory.WithDbContextAsync(async db =>
        {
            var updated = await db.Naudotojai.FindAsync(user.Id);
            Assert.NotNull(updated);
            Assert.True(updated!.Adminas);
        });
    }

    [Fact]
    public async Task ChangePassword_Returns_Forbidden_When_User_Tries_To_Change_Other_User()
    {
        await _factory.ResetDatabaseAsync();

        var currentUserId = Guid.NewGuid();
        var otherUserId = Guid.NewGuid();

        await _factory.WithDbContextAsync(async db =>
        {
            db.Naudotojai.Add(new Naudotojas
            {
                Id = otherUserId,
                Vardas = "O",
                Pavarde = "U",
                GimimoData = new DateTime(2000, 1, 1, 0, 0, 0, DateTimeKind.Utc),
                Adminas = false,
                PrisijungimoId = "o.u.123",
                PasswordHash = BCrypt.Net.BCrypt.HashPassword("secret1"),
                SuperAdminas = false,
                MustChangePassword = false,
            });
            await db.SaveChangesAsync();
        });

        var client = _factory.CreateClient().AsUser(currentUserId);
        var res = await client.PutAsJsonAsync($"/api/Naudotojas/changePassword/{otherUserId}", new
        {
            currentPassword = "secret1",
            newPassword = "secret2",
        });

        Assert.Equal(HttpStatusCode.Forbidden, res.StatusCode);
        using var doc = JsonDocument.Parse(await res.Content.ReadAsStringAsync());
        Assert.Equal("Neturite teisių atlikti šį veiksmą.", doc.RootElement.GetProperty("message").GetString());
    }

    [Fact]
    public async Task ChangePassword_Returns_Unauthorized_When_CurrentPassword_Is_Wrong()
    {
        await _factory.ResetDatabaseAsync();

        var userId = Guid.NewGuid();
        await _factory.WithDbContextAsync(async db =>
        {
            db.Naudotojai.Add(new Naudotojas
            {
                Id = userId,
                Vardas = "A",
                Pavarde = "B",
                GimimoData = new DateTime(2000, 1, 1, 0, 0, 0, DateTimeKind.Utc),
                Adminas = false,
                PrisijungimoId = "a.b.123",
                PasswordHash = BCrypt.Net.BCrypt.HashPassword("correct"),
                SuperAdminas = false,
                MustChangePassword = true,
            });
            await db.SaveChangesAsync();
        });

        var client = _factory.CreateClient().AsUser(userId);
        var res = await client.PutAsJsonAsync($"/api/Naudotojas/changePassword/{userId}", new
        {
            currentPassword = "wrong",
            newPassword = "newpass",
        });

        Assert.Equal(HttpStatusCode.Unauthorized, res.StatusCode);
    }

    [Fact]
    public async Task ChangePassword_Works_For_Self_And_Revokes_RefreshTokens()
    {
        await _factory.ResetDatabaseAsync();

        var userId = Guid.NewGuid();
        var activeToken = new RefreshToken
        {
            Id = Guid.NewGuid(),
            Token = "t1",
            Expires = DateTime.UtcNow.AddDays(1),
            Revoked = null,
            NaudotojasId = userId,
        };

        await _factory.WithDbContextAsync(async db =>
        {
            db.Naudotojai.Add(new Naudotojas
            {
                Id = userId,
                Vardas = "A",
                Pavarde = "B",
                GimimoData = new DateTime(2000, 1, 1, 0, 0, 0, DateTimeKind.Utc),
                Adminas = false,
                PrisijungimoId = "a.b.123",
                PasswordHash = BCrypt.Net.BCrypt.HashPassword("oldpass"),
                SuperAdminas = false,
                MustChangePassword = true,
            });
            db.RefreshTokens.Add(activeToken);
            await db.SaveChangesAsync();
        });

        var client = _factory.CreateClient().AsUser(userId);
        var res = await client.PutAsJsonAsync($"/api/Naudotojas/changePassword/{userId}", new
        {
            currentPassword = "oldpass",
            newPassword = "newpass",
        });
        Assert.Equal(HttpStatusCode.NoContent, res.StatusCode);

        await _factory.WithDbContextAsync(async db =>
        {
            var user = await db.Naudotojai.FindAsync(userId);
            Assert.NotNull(user);
            Assert.False(user!.MustChangePassword);

            var token = await db.RefreshTokens.FindAsync(activeToken.Id);
            Assert.NotNull(token);
            Assert.NotNull(token!.Revoked);
        });
    }

    [Fact]
    public async Task AdminSetPassword_Works_And_Marks_MustChangePassword_And_Revokes_RefreshTokens()
    {
        await _factory.ResetDatabaseAsync();

        var targetUserId = Guid.NewGuid();
        var activeToken = new RefreshToken
        {
            Id = Guid.NewGuid(),
            Token = "t1",
            Expires = DateTime.UtcNow.AddDays(1),
            Revoked = null,
            NaudotojasId = targetUserId,
        };

        await _factory.WithDbContextAsync(async db =>
        {
            db.Naudotojai.Add(new Naudotojas
            {
                Id = targetUserId,
                Vardas = "A",
                Pavarde = "B",
                GimimoData = new DateTime(2000, 1, 1, 0, 0, 0, DateTimeKind.Utc),
                Adminas = false,
                PrisijungimoId = "a.b.123",
                PasswordHash = BCrypt.Net.BCrypt.HashPassword("oldpass"),
                SuperAdminas = false,
                MustChangePassword = false,
            });
            db.RefreshTokens.Add(activeToken);
            await db.SaveChangesAsync();
        });

        var client = _factory.CreateClient().AsAdmin();
        var res = await client.PutAsJsonAsync($"/api/Naudotojas/setPassword/{targetUserId}", new { newPassword = "newpass" });
        Assert.Equal(HttpStatusCode.NoContent, res.StatusCode);

        await _factory.WithDbContextAsync(async db =>
        {
            var user = await db.Naudotojai.FindAsync(targetUserId);
            Assert.NotNull(user);
            Assert.True(user!.MustChangePassword);

            var token = await db.RefreshTokens.FindAsync(activeToken.Id);
            Assert.NotNull(token);
            Assert.NotNull(token!.Revoked);
        });
    }

    [Fact]
    public async Task Create_Returns_BadRequest_When_Name_Missing()
    {
        await _factory.ResetDatabaseAsync();

        var client = _factory.CreateClient().AsAdmin();
        var res = await client.PostAsJsonAsync("/api/Naudotojas", new
        {
            vardas = "",
            pavarde = "Jonaitis",
            gimimoData = new DateTime(2000, 1, 1),
            adminas = false,
            password = "secret1",
        });

        Assert.Equal(HttpStatusCode.BadRequest, res.StatusCode);
    }

    [Fact]
    public async Task Create_Returns_BadRequest_When_Password_Too_Short()
    {
        await _factory.ResetDatabaseAsync();

        var client = _factory.CreateClient().AsAdmin();
        var res = await client.PostAsJsonAsync("/api/Naudotojas", new
        {
            vardas = "Jonas",
            pavarde = "Jonaitis",
            gimimoData = new DateTime(2000, 1, 1),
            adminas = false,
            password = "123",
        });

        Assert.Equal(HttpStatusCode.BadRequest, res.StatusCode);
    }

    [Fact]
    public async Task ChangePassword_Returns_BadRequest_When_Fields_Missing()
    {
        await _factory.ResetDatabaseAsync();

        var userId = Guid.NewGuid();
        await _factory.WithDbContextAsync(async db =>
        {
            db.Naudotojai.Add(new Naudotojas
            {
                Id = userId,
                Vardas = "A",
                Pavarde = "B",
                GimimoData = new DateTime(2000, 1, 1, 0, 0, 0, DateTimeKind.Utc),
                Adminas = false,
                PrisijungimoId = "a.b.123",
                PasswordHash = BCrypt.Net.BCrypt.HashPassword("oldpass"),
                SuperAdminas = false,
                MustChangePassword = true,
            });
            await db.SaveChangesAsync();
        });

        var client = _factory.CreateClient().AsUser(userId);
        var res = await client.PutAsJsonAsync($"/api/Naudotojas/changePassword/{userId}", new
        {
            currentPassword = "",
            newPassword = "",
        });

        Assert.Equal(HttpStatusCode.BadRequest, res.StatusCode);
    }

    [Fact]
    public async Task ChangePassword_Returns_NotFound_When_Target_User_Does_Not_Exist()
    {
        await _factory.ResetDatabaseAsync();

        var userId = Guid.NewGuid();
        var client = _factory.CreateClient().AsUser(userId);

        var res = await client.PutAsJsonAsync($"/api/Naudotojas/changePassword/{userId}", new
        {
            currentPassword = "oldpass",
            newPassword = "newpass",
        });

        Assert.Equal(HttpStatusCode.NotFound, res.StatusCode);
    }

    [Fact]
    public async Task AdminSetPassword_Returns_Forbidden_When_Target_Is_Admin_And_Caller_Is_Not_SuperAdmin()
    {
        await _factory.ResetDatabaseAsync();

        var targetUserId = Guid.NewGuid();
        await _factory.WithDbContextAsync(async db =>
        {
            db.Naudotojai.Add(new Naudotojas
            {
                Id = targetUserId,
                Vardas = "Admin",
                Pavarde = "User",
                GimimoData = new DateTime(2000, 1, 1, 0, 0, 0, DateTimeKind.Utc),
                Adminas = true,
                PrisijungimoId = "admin.user",
                PasswordHash = BCrypt.Net.BCrypt.HashPassword("oldpass"),
                SuperAdminas = false,
                MustChangePassword = false,
            });
            await db.SaveChangesAsync();
        });

        var client = _factory.CreateClient().AsAdmin();
        var res = await client.PutAsJsonAsync($"/api/Naudotojas/setPassword/{targetUserId}", new { newPassword = "newpass" });

        Assert.Equal(HttpStatusCode.Forbidden, res.StatusCode);
    }
}
