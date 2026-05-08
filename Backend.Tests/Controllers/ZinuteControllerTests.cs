using System.Net;
using System.Net.Http.Json;
using Backend.Models;
using Backend.Tests.Testing;
using Microsoft.EntityFrameworkCore;

namespace Backend.Tests.Controllers;

public sealed class ZinuteControllerTests : IClassFixture<CustomWebApplicationFactory>
{
    private readonly CustomWebApplicationFactory _factory;

    public ZinuteControllerTests(CustomWebApplicationFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task Create_Works_For_Admin()
    {
        await _factory.ResetDatabaseAsync();
        var client = _factory.CreateClient().AsAdmin();

        var createRes = await client.PostAsJsonAsync("/api/Zinute", new { tekstas = "Hello" });
        Assert.Equal(HttpStatusCode.Created, createRes.StatusCode);

        var created = await createRes.Content.ReadFromJsonAsync<Zinute>();
        Assert.NotNull(created);
        Assert.True(created!.Id > 0);
        Assert.Equal("Hello", created.Tekstas);
    }

    [Fact]
    public async Task GetAll_Returns_Items()
    {
        await _factory.ResetDatabaseAsync();
        var client = _factory.CreateClient().AsAdmin();

        await client.PostAsJsonAsync("/api/Zinute", new { tekstas = "A" });
        await client.PostAsJsonAsync("/api/Zinute", new { tekstas = "B" });

        var listRes = await client.GetAsync("/api/Zinute");
        Assert.Equal(HttpStatusCode.OK, listRes.StatusCode);

        var list = await listRes.Content.ReadFromJsonAsync<List<Zinute>>();
        Assert.NotNull(list);
        Assert.True(list!.Count >= 2);
    }

    [Fact]
    public async Task Update_Works_For_Admin()
    {
        await _factory.ResetDatabaseAsync();
        var client = _factory.CreateClient().AsAdmin();

        var createRes = await client.PostAsJsonAsync("/api/Zinute", new { tekstas = "Hello" });
        var created = await createRes.Content.ReadFromJsonAsync<Zinute>();
        Assert.NotNull(created);

        var updateRes = await client.PutAsJsonAsync($"/api/Zinute/{created!.Id}", new { tekstas = "Updated" });
        Assert.Equal(HttpStatusCode.NoContent, updateRes.StatusCode);

        var getRes = await client.GetAsync($"/api/Zinute/{created.Id}");
        Assert.Equal(HttpStatusCode.OK, getRes.StatusCode);
        var fetched = await getRes.Content.ReadFromJsonAsync<Zinute>();
        Assert.NotNull(fetched);
        Assert.Equal("Updated", fetched!.Tekstas);
    }

    [Fact]
    public async Task Delete_Works_For_Admin()
    {
        await _factory.ResetDatabaseAsync();
        var client = _factory.CreateClient().AsAdmin();

        var createRes = await client.PostAsJsonAsync("/api/Zinute", new { tekstas = "Hello" });
        var created = await createRes.Content.ReadFromJsonAsync<Zinute>();
        Assert.NotNull(created);

        var delRes = await client.DeleteAsync($"/api/Zinute/{created!.Id}");
        Assert.Equal(HttpStatusCode.NoContent, delRes.StatusCode);

        var getRes2 = await client.GetAsync($"/api/Zinute/{created.Id}");
        Assert.Equal(HttpStatusCode.NotFound, getRes2.StatusCode);
    }

    [Fact]
    public async Task Create_Rejects_Empty_Text()
    {
        await _factory.ResetDatabaseAsync();
        var client = _factory.CreateClient().AsAdmin();
        var createRes = await client.PostAsJsonAsync("/api/Zinute", new { tekstas = "   " });
        Assert.Equal(HttpStatusCode.BadRequest, createRes.StatusCode);
    }

    [Fact]
    public async Task SendToAdmins_Rejects_Empty_Text()
    {
        await _factory.ResetDatabaseAsync();
        var client = _factory.CreateClient().AsUser(Guid.NewGuid());

        var res = await client.PostAsJsonAsync("/api/Zinute/sendToAdmins", new { tekstas = "   " });
        Assert.Equal(HttpStatusCode.BadRequest, res.StatusCode);

        var body = await res.Content.ReadFromJsonAsync<Dictionary<string, string>>();
        Assert.NotNull(body);
        Assert.Equal("Tekstas yra būtinas", body!["message"]);
    }

    [Fact]
    public async Task SendToAdmins_Creates_Zinute_And_Links_For_Admins()
    {
        await _factory.ResetDatabaseAsync();

        var admin1 = new Naudotojas
        {
            Vardas = "A1",
            Pavarde = "P",
            GimimoData = DateTime.UtcNow.AddYears(-20),
            Adminas = true,
            PasswordHash = "hash",
            PrisijungimoId = "a1",
            SuperAdminas = false,
            MustChangePassword = false,
        };

        var admin2 = new Naudotojas
        {
            Vardas = "A2",
            Pavarde = "P",
            GimimoData = DateTime.UtcNow.AddYears(-21),
            Adminas = true,
            PasswordHash = "hash",
            PrisijungimoId = "a2",
            SuperAdminas = false,
            MustChangePassword = false,
        };

        var user = new Naudotojas
        {
            Vardas = "U",
            Pavarde = "P",
            GimimoData = DateTime.UtcNow.AddYears(-22),
            Adminas = false,
            PasswordHash = "hash",
            PrisijungimoId = "u",
            SuperAdminas = false,
            MustChangePassword = false,
        };

        await _factory.WithDbContextAsync(async db =>
        {
            db.Naudotojai.AddRange(admin1, admin2, user);
            await db.SaveChangesAsync();
        });

        var client = _factory.CreateClient().AsUser(user.Id);
        var res = await client.PostAsJsonAsync("/api/Zinute/sendToAdmins", new { tekstas = "  Hello  " });
        Assert.Equal(HttpStatusCode.Created, res.StatusCode);

        var created = await res.Content.ReadFromJsonAsync<Zinute>();
        Assert.NotNull(created);
        Assert.True(created!.Id > 0);
        Assert.Equal("Hello", created.Tekstas);

        await _factory.WithDbContextAsync(async db =>
        {
            var links = await db.NaudotojasZinute
                .AsNoTracking()
                .Where(nz => nz.Zinuteid == created.Id)
                .ToListAsync();

            Assert.Equal(2, links.Count);
            Assert.All(links, l => Assert.False(l.Perskaityta));
            Assert.Contains(links, l => l.Naudotojasid == admin1.Id);
            Assert.Contains(links, l => l.Naudotojasid == admin2.Id);
            Assert.DoesNotContain(links, l => l.Naudotojasid == user.Id);
        });
    }
}
