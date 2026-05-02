using System.Net;
using System.Net.Http;
using System.Net.Http.Json;
using Backend.Models;
using Backend.Tests.Testing;

namespace Backend.Tests.Controllers;

public sealed class TestasIrasasControllerTests : IClassFixture<CustomWebApplicationFactory>
{
    private readonly CustomWebApplicationFactory _factory;

    public TestasIrasasControllerTests(CustomWebApplicationFactory factory)
    {
        _factory = factory;
    }

    private async Task<(HttpClient client, TestasIrasas link1, TestasIrasas link2)> SeedTwoLinksAsync()
    {
        await _factory.ResetDatabaseAsync();
        var client = _factory.CreateClient().AsAdmin();

        var lok = new Lokacija { Pavadinimas = "L" };
        var irasas = new Irasas
        {
            IdDokumento = "doc",
            Pavadinimas = "irasas",
            LokacijaId = 0,
            Pradzia = DateTime.UtcNow,
            Statusas = "Nepradėtas",
        };
        var t1 = new Testas { Testotekstas = "T1" };
        var t2 = new Testas { Testotekstas = "T2" };

        await _factory.WithDbContextAsync(async db =>
        {
            db.Lokacijos.Add(lok);
            await db.SaveChangesAsync();

            irasas.LokacijaId = lok.Id;
            db.Irasai.Add(irasas);
            db.Testai.AddRange(t1, t2);
            await db.SaveChangesAsync();
        });

        var create1 = await client.PostAsJsonAsync("/api/TestasIrasas", new { testasid = t1.Id, irasasid = irasas.Id });
        Assert.Equal(HttpStatusCode.Created, create1.StatusCode);
        var link1 = await create1.Content.ReadFromJsonAsync<TestasIrasas>();
        Assert.NotNull(link1);

        var create2 = await client.PostAsJsonAsync("/api/TestasIrasas", new { testasid = t2.Id, irasasid = irasas.Id });
        Assert.Equal(HttpStatusCode.Created, create2.StatusCode);
        var link2 = await create2.Content.ReadFromJsonAsync<TestasIrasas>();
        Assert.NotNull(link2);

        return (client, link1!, link2!);
    }

    [Fact]
    public async Task Create_Sets_Eile_For_Admin()
    {
        var (_, link1, link2) = await SeedTwoLinksAsync();
        Assert.Equal(1, link1.Eile);
        Assert.Equal(2, link2.Eile);
    }

    [Fact]
    public async Task GetById_Works_For_Admin()
    {
        var (client, _, link2) = await SeedTwoLinksAsync();

        var get = await client.GetAsync($"/api/TestasIrasas/{link2.Id}");
        Assert.Equal(HttpStatusCode.OK, get.StatusCode);
    }

    [Fact]
    public async Task Update_Works_For_Admin()
    {
        var (client, _, link2) = await SeedTwoLinksAsync();

        var update = await client.PutAsJsonAsync($"/api/TestasIrasas/{link2.Id}", new
        {
            id = link2.Id,
            testasid = link2.Testasid,
            irasasid = link2.Irasasid,
            eile = link2.Eile,
        });
        Assert.Equal(HttpStatusCode.NoContent, update.StatusCode);
    }

    [Fact]
    public async Task Delete_Works_For_Admin()
    {
        var (client, link1, _) = await SeedTwoLinksAsync();

        var del = await client.DeleteAsync($"/api/TestasIrasas/{link1.Id}");
        Assert.Equal(HttpStatusCode.NoContent, del.StatusCode);

        var getDeleted = await client.GetAsync($"/api/TestasIrasas/{link1.Id}");
        Assert.Equal(HttpStatusCode.NotFound, getDeleted.StatusCode);
    }
}
