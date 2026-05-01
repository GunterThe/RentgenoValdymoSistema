using System.Net;
using System.Net.Http.Json;
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

    [Fact]
    public async Task Admin_Can_Create_List_Get_And_Delete_User()
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
        Assert.Equal("Jonas", created.Vardas);

        var listRes = await client.GetAsync("/api/Naudotojas");
        Assert.Equal(HttpStatusCode.OK, listRes.StatusCode);
        var list = await listRes.Content.ReadFromJsonAsync<List<NaudotojasController.NaudotojasListItem>>();
        Assert.NotNull(list);
        Assert.Contains(list!, u => u.Id == created.Id);

        var getRes = await client.GetAsync($"/api/Naudotojas/{created.Id}");
        Assert.Equal(HttpStatusCode.OK, getRes.StatusCode);
        var fetched = await getRes.Content.ReadFromJsonAsync<Naudotojas>();
        Assert.NotNull(fetched);

        // This endpoint intentionally hides sensitive fields.
        Assert.Equal(string.Empty, fetched!.PasswordHash);
        Assert.Equal(string.Empty, fetched.PrisijungimoId);
        Assert.False(fetched.Adminas);

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
}
