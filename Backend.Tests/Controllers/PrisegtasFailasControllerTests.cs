using System.Net;
using System.Net.Http.Json;
using Backend.Models;
using Backend.Tests.Testing;

namespace Backend.Tests.Controllers;

public sealed class PrisegtasFailasControllerTests : IClassFixture<CustomWebApplicationFactory>
{
    private readonly CustomWebApplicationFactory _factory;

    public PrisegtasFailasControllerTests(CustomWebApplicationFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task Create_Works_For_Authorized_User()
    {
        await _factory.ResetDatabaseAsync();
        var client = _factory.CreateClient().AsUser(Guid.NewGuid());

        var id = Guid.NewGuid();
        var createRes = await client.PostAsJsonAsync("/api/PrisegtasFailas", new
        {
            id,
            zingsnisId = (int?)null,
            zingsnisTemplateId = (int?)null,
            failoPav = "a.png",
            dydis = 123,
            nuoroda = (string?)null,
            sukurimoLaikas = DateTime.UtcNow,
        });

        Assert.Equal(HttpStatusCode.Created, createRes.StatusCode);
        var created = await createRes.Content.ReadFromJsonAsync<PrisegtasFailas>();
        Assert.NotNull(created);
        Assert.Equal(id, created!.Id);
    }

    [Fact]
    public async Task GetById_Works_For_Authorized_User()
    {
        await _factory.ResetDatabaseAsync();
        var client = _factory.CreateClient().AsUser(Guid.NewGuid());

        var id = Guid.NewGuid();
        await client.PostAsJsonAsync("/api/PrisegtasFailas", new
        {
            id,
            zingsnisId = (int?)null,
            zingsnisTemplateId = (int?)null,
            failoPav = "a.png",
            dydis = 123,
            nuoroda = (string?)null,
            sukurimoLaikas = DateTime.UtcNow,
        });

        var get = await client.GetAsync($"/api/PrisegtasFailas/{id}");
        Assert.Equal(HttpStatusCode.OK, get.StatusCode);
    }

    [Fact]
    public async Task Update_Works_For_Authorized_User()
    {
        await _factory.ResetDatabaseAsync();
        var client = _factory.CreateClient().AsUser(Guid.NewGuid());

        var id = Guid.NewGuid();
        await client.PostAsJsonAsync("/api/PrisegtasFailas", new
        {
            id,
            zingsnisId = (int?)null,
            zingsnisTemplateId = (int?)null,
            failoPav = "a.png",
            dydis = 123,
            nuoroda = (string?)null,
            sukurimoLaikas = DateTime.UtcNow,
        });

        var updateRes = await client.PutAsJsonAsync($"/api/PrisegtasFailas/{id}", new
        {
            id,
            zingsnisId = (int?)null,
            zingsnisTemplateId = (int?)null,
            failoPav = "b.png",
            dydis = 456,
            nuoroda = (string?)null,
            sukurimoLaikas = DateTime.UtcNow,
        });
        Assert.Equal(HttpStatusCode.NoContent, updateRes.StatusCode);

        var get2 = await client.GetAsync($"/api/PrisegtasFailas/{id}");
        var updated = await get2.Content.ReadFromJsonAsync<PrisegtasFailas>();
        Assert.NotNull(updated);
        Assert.Equal("b.png", updated!.FailoPav);
    }

    [Fact]
    public async Task Delete_Works_For_Authorized_User()
    {
        await _factory.ResetDatabaseAsync();
        var client = _factory.CreateClient().AsUser(Guid.NewGuid());

        var id = Guid.NewGuid();
        await client.PostAsJsonAsync("/api/PrisegtasFailas", new
        {
            id,
            zingsnisId = (int?)null,
            zingsnisTemplateId = (int?)null,
            failoPav = "a.png",
            dydis = 123,
            nuoroda = (string?)null,
            sukurimoLaikas = DateTime.UtcNow,
        });

        var del = await client.DeleteAsync($"/api/PrisegtasFailas/{id}");
        Assert.Equal(HttpStatusCode.NoContent, del.StatusCode);

        var getDeleted = await client.GetAsync($"/api/PrisegtasFailas/{id}");
        Assert.Equal(HttpStatusCode.NotFound, getDeleted.StatusCode);
    }

    [Fact]
    public async Task GetByZingsnis_Returns_Only_Matching()
    {
        await _factory.ResetDatabaseAsync();

        Guid userId = Guid.NewGuid();
        int zingsnisId = 0;
        Guid fileId = Guid.NewGuid();

        await _factory.WithDbContextAsync(async db =>
        {
            var user = new Naudotojas
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
            };
            db.Naudotojai.Add(user);

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

            var z = new Zingsnis
            {
                Komentaras = "c",
                CompletedAt = null,
                TestasIrasasId = link.Id,
                ZingsnisTemplateId = tpl.Id,
                CompletedByUserId = userId,
            };
            db.Zingsniai.Add(z);
            await db.SaveChangesAsync();

            zingsnisId = z.Id;

            db.PrisegtiFailai.Add(new PrisegtasFailas
            {
                Id = fileId,
                ZingsnisId = zingsnisId,
                FailoPav = "x.jpg",
                Dydis = 1,
                Nuoroda = null,
                SukurimoLaikas = DateTime.UtcNow,
            });
            db.PrisegtiFailai.Add(new PrisegtasFailas
            {
                Id = Guid.NewGuid(),
                ZingsnisId = null,
                FailoPav = "y.jpg",
                Dydis = 1,
                Nuoroda = null,
                SukurimoLaikas = DateTime.UtcNow,
            });

            await db.SaveChangesAsync();
        });

        var client = _factory.CreateClient();
        var res = await client.GetAsync($"/api/PrisegtasFailas/byZingsnis/{zingsnisId}");
        Assert.Equal(HttpStatusCode.OK, res.StatusCode);

        var list = await res.Content.ReadFromJsonAsync<List<PrisegtasFailas>>();
        Assert.NotNull(list);
        Assert.Single(list!);
        Assert.Equal(fileId, list[0].Id);
    }
}
