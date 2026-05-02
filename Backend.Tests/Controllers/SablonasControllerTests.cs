using System.Net;
using System.Net.Http.Json;
using Backend.Models;
using Backend.Tests.Testing;

namespace Backend.Tests.Controllers;

public sealed class SablonasControllerTests : IClassFixture<CustomWebApplicationFactory>
{
    private readonly CustomWebApplicationFactory _factory;

    public SablonasControllerTests(CustomWebApplicationFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task Create_Works_For_Admin()
    {
        await _factory.ResetDatabaseAsync();
        var client = _factory.CreateClient().AsAdmin();

        var createRes = await client.PostAsJsonAsync("/api/Sablonas", new { pavadinimas = "S1" });
        Assert.Equal(HttpStatusCode.Created, createRes.StatusCode);
        var created = await createRes.Content.ReadFromJsonAsync<Sablonas>();
        Assert.NotNull(created);
        Assert.True(created!.Id > 0);
        Assert.Equal("S1", created.Pavadinimas);
    }

    [Fact]
    public async Task GetById_Returns_Item()
    {
        await _factory.ResetDatabaseAsync();
        var client = _factory.CreateClient().AsAdmin();

        var createRes = await client.PostAsJsonAsync("/api/Sablonas", new { pavadinimas = "S1" });
        var created = await createRes.Content.ReadFromJsonAsync<Sablonas>();
        Assert.NotNull(created);

        var getRes = await client.GetAsync($"/api/Sablonas/{created!.Id}");
        Assert.Equal(HttpStatusCode.OK, getRes.StatusCode);
    }

    [Fact]
    public async Task Update_Works_For_Admin()
    {
        await _factory.ResetDatabaseAsync();
        var client = _factory.CreateClient().AsAdmin();

        var createRes = await client.PostAsJsonAsync("/api/Sablonas", new { pavadinimas = "S1" });
        var created = await createRes.Content.ReadFromJsonAsync<Sablonas>();
        Assert.NotNull(created);

        var updateRes = await client.PutAsJsonAsync($"/api/Sablonas/{created!.Id}", new { id = created.Id, pavadinimas = "S2" });
        Assert.Equal(HttpStatusCode.NoContent, updateRes.StatusCode);

        var getRes = await client.GetAsync($"/api/Sablonas/{created.Id}");
        var fetched = await getRes.Content.ReadFromJsonAsync<Sablonas>();
        Assert.NotNull(fetched);
        Assert.Equal("S2", fetched!.Pavadinimas);
    }

    [Fact]
    public async Task Delete_Works_For_Admin()
    {
        await _factory.ResetDatabaseAsync();
        var client = _factory.CreateClient().AsAdmin();

        var createRes = await client.PostAsJsonAsync("/api/Sablonas", new { pavadinimas = "S1" });
        var created = await createRes.Content.ReadFromJsonAsync<Sablonas>();
        Assert.NotNull(created);

        var delRes = await client.DeleteAsync($"/api/Sablonas/{created!.Id}");
        Assert.Equal(HttpStatusCode.NoContent, delRes.StatusCode);

        var getRes2 = await client.GetAsync($"/api/Sablonas/{created.Id}");
        Assert.Equal(HttpStatusCode.NotFound, getRes2.StatusCode);
    }
}
