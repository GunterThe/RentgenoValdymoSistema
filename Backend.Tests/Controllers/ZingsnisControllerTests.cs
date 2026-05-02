using System.Net;
using System.Net.Http.Json;
using Backend.Models;
using Backend.Tests.Testing;

namespace Backend.Tests.Controllers;

public sealed class ZingsnisControllerTests : IClassFixture<CustomWebApplicationFactory>
{
    private readonly CustomWebApplicationFactory _factory;

    public ZingsnisControllerTests(CustomWebApplicationFactory factory)
    {
        _factory = factory;
    }

    private async Task<(Guid userId, int linkId, int tplId, int zingsnisId)> SeedZingsnisAsync()
    {
        await _factory.ResetDatabaseAsync();

        Guid userId = Guid.NewGuid();
        int linkId = 0;
        int tplId = 0;

        await _factory.WithDbContextAsync(async db =>
        {
            db.Naudotojai.Add(new Naudotojas
            {
                Id = userId,
                Vardas = "V",
                Pavarde = "P",
                GimimoData = new DateTime(2000, 1, 1),
                Adminas = false,
                SuperAdminas = false,
                PrisijungimoId = "u",
                PasswordHash = BCrypt.Net.BCrypt.HashPassword("pass"),
                MustChangePassword = false,
            });

            var lok = new Lokacija { Pavadinimas = "L" };
            db.Lokacijos.Add(lok);
            await db.SaveChangesAsync();

            var irasas = new Irasas
            {
                IdDokumento = "doc",
                Pavadinimas = "irasas",
                LokacijaId = lok.Id,
                Pradzia = DateTime.UtcNow,
                Statusas = "Nepradėtas",
            };
            db.Irasai.Add(irasas);

            var testas = new Testas { Testotekstas = "T" };
            db.Testai.Add(testas);
            await db.SaveChangesAsync();

            var link = new TestasIrasas { Testasid = testas.Id, Irasasid = irasas.Id, Eile = 1 };
            db.TestasIrasai.Add(link);

            var tpl = new ZingsnisTemplate
            {
                Pavadinimas = "Z",
                Aprasymas = "A",
                TestasId = testas.Id,
                Eile = 1,
                KomentarasPrivalomas = false,
                NuotraukaPrivaloma = false,
            };
            db.ZingsnisTemplate.Add(tpl);
            await db.SaveChangesAsync();

            linkId = link.Id;
            tplId = tpl.Id;
        });

        var userClient = _factory.CreateClient().AsUser(userId);
        var create = await userClient.PostAsJsonAsync("/api/Zingsnis", new
        {
            komentaras = "c",
            completedAt = (DateTime?)null,
            testasIrasasId = linkId,
            zingsnisTemplateId = tplId,
            completedByUserId = userId,
        });
        Assert.Equal(HttpStatusCode.Created, create.StatusCode);
        var created = await create.Content.ReadFromJsonAsync<Zingsnis>();
        Assert.NotNull(created);

        return (userId, linkId, tplId, created!.Id);
    }

    [Fact]
    public async Task Create_Works_For_User()
    {
        var (_, _, _, zingsnisId) = await SeedZingsnisAsync();
        Assert.True(zingsnisId > 0);
    }

    [Fact]
    public async Task GetById_Works_For_User()
    {
        var (userId, _, _, zingsnisId) = await SeedZingsnisAsync();
        var userClient = _factory.CreateClient().AsUser(userId);

        var get = await userClient.GetAsync($"/api/Zingsnis/{zingsnisId}");
        Assert.Equal(HttpStatusCode.OK, get.StatusCode);
    }

    [Fact]
    public async Task GetByEverything_Works_For_User()
    {
        var (userId, linkId, tplId, _) = await SeedZingsnisAsync();
        var userClient = _factory.CreateClient().AsUser(userId);

        var getByEverything = await userClient.GetAsync($"/api/Zingsnis/getByEverything/{linkId}/{tplId}");
        Assert.Equal(HttpStatusCode.OK, getByEverything.StatusCode);
    }

    [Fact]
    public async Task Update_Works_For_User()
    {
        var (userId, linkId, tplId, zingsnisId) = await SeedZingsnisAsync();
        var userClient = _factory.CreateClient().AsUser(userId);

        var update = await userClient.PutAsJsonAsync($"/api/Zingsnis/{zingsnisId}", new
        {
            id = zingsnisId,
            komentaras = "updated",
            completedAt = (DateTime?)null,
            testasIrasasId = linkId,
            zingsnisTemplateId = tplId,
            completedByUserId = userId,
        });
        Assert.Equal(HttpStatusCode.NoContent, update.StatusCode);

        var get2 = await userClient.GetAsync($"/api/Zingsnis/{zingsnisId}");
        var fetched2 = await get2.Content.ReadFromJsonAsync<Zingsnis>();
        Assert.NotNull(fetched2);
        Assert.Equal("updated", fetched2!.Komentaras);
    }

    [Fact]
    public async Task Delete_Works_For_Admin()
    {
        var (userId, _, _, zingsnisId) = await SeedZingsnisAsync();

        var adminClient = _factory.CreateClient().AsAdmin();
        var del = await adminClient.DeleteAsync($"/api/Zingsnis/{zingsnisId}");
        Assert.Equal(HttpStatusCode.NoContent, del.StatusCode);

        var userClient = _factory.CreateClient().AsUser(userId);
        var getDeleted = await userClient.GetAsync($"/api/Zingsnis/{zingsnisId}");
        Assert.Equal(HttpStatusCode.NotFound, getDeleted.StatusCode);
    }
}
