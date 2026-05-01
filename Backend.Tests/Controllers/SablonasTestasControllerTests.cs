using System.Net;
using System.Net.Http.Json;
using Backend.Models;
using Backend.Tests.Testing;

namespace Backend.Tests.Controllers;

public sealed class SablonasTestasControllerTests : IClassFixture<CustomWebApplicationFactory>
{
    private readonly CustomWebApplicationFactory _factory;

    public SablonasTestasControllerTests(CustomWebApplicationFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task Create_Get_Delete_Works_For_Admin()
    {
        await _factory.ResetDatabaseAsync();
        var client = _factory.CreateClient().AsAdmin();

        var sablonas = new Sablonas { Pavadinimas = "S" };
        var testas = new Testas { Testotekstas = "T" };

        await _factory.WithDbContextAsync(async db =>
        {
            db.Sablonai.Add(sablonas);
            db.Testai.Add(testas);
            await db.SaveChangesAsync();
        });

        var createRes = await client.PostAsJsonAsync("/api/SablonasTestas", new
        {
            sablonasid = sablonas.Id,
            testasid = testas.Id,
        });

        Assert.Equal(HttpStatusCode.Created, createRes.StatusCode);
        var created = await createRes.Content.ReadFromJsonAsync<SablonasTestas>();
        Assert.NotNull(created);
        Assert.Equal(sablonas.Id, created!.Sablonasid);
        Assert.Equal(testas.Id, created.Testasid);

        var getRes = await client.GetAsync($"/api/SablonasTestas/{sablonas.Id}/{testas.Id}");
        Assert.Equal(HttpStatusCode.OK, getRes.StatusCode);

        var delRes = await client.DeleteAsync($"/api/SablonasTestas/{sablonas.Id}/{testas.Id}");
        Assert.Equal(HttpStatusCode.NoContent, delRes.StatusCode);

        var getRes2 = await client.GetAsync($"/api/SablonasTestas/{sablonas.Id}/{testas.Id}");
        Assert.Equal(HttpStatusCode.NotFound, getRes2.StatusCode);
    }
}
