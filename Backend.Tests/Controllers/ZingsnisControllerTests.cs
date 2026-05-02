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

    [Fact]
    public async Task Crud_Works_For_User_And_Delete_For_Admin()
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
        Assert.True(created!.Id > 0);

        var get = await userClient.GetAsync($"/api/Zingsnis/{created.Id}");
        Assert.Equal(HttpStatusCode.OK, get.StatusCode);

        var getByEverything = await userClient.GetAsync($"/api/Zingsnis/getByEverything/{linkId}/{tplId}");
        Assert.Equal(HttpStatusCode.OK, getByEverything.StatusCode);

        var update = await userClient.PutAsJsonAsync($"/api/Zingsnis/{created.Id}", new
        {
            id = created.Id,
            komentaras = "updated",
            completedAt = (DateTime?)null,
            testasIrasasId = linkId,
            zingsnisTemplateId = tplId,
            completedByUserId = userId,
        });
        Assert.Equal(HttpStatusCode.NoContent, update.StatusCode);

        var get2 = await userClient.GetAsync($"/api/Zingsnis/{created.Id}");
        var fetched2 = await get2.Content.ReadFromJsonAsync<Zingsnis>();
        Assert.NotNull(fetched2);
        Assert.Equal("updated", fetched2!.Komentaras);

        var adminClient = _factory.CreateClient().AsAdmin();
        var del = await adminClient.DeleteAsync($"/api/Zingsnis/{created.Id}");
        Assert.Equal(HttpStatusCode.NoContent, del.StatusCode);

        var getDeleted = await userClient.GetAsync($"/api/Zingsnis/{created.Id}");
        Assert.Equal(HttpStatusCode.NotFound, getDeleted.StatusCode);
    }
}
