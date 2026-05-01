using System.Net;
using System.Net.Http.Json;
using Backend.Models;
using Backend.Tests.Testing;

namespace Backend.Tests.Controllers;

public sealed class ZinuteControllerTests : IClassFixture<CustomWebApplicationFactory>
{
    private readonly CustomWebApplicationFactory _factory;

    public ZinuteControllerTests(CustomWebApplicationFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task Crud_Works_For_Admin()
    {
        await _factory.ResetDatabaseAsync();
        var client = _factory.CreateClient().AsAdmin();

        var createRes = await client.PostAsJsonAsync("/api/Zinute", new { tekstas = "Hello" });
        Assert.Equal(HttpStatusCode.Created, createRes.StatusCode);
        var created = await createRes.Content.ReadFromJsonAsync<Zinute>();
        Assert.NotNull(created);
        Assert.True(created!.Id > 0);

        var listRes = await client.GetAsync("/api/Zinute");
        Assert.Equal(HttpStatusCode.OK, listRes.StatusCode);

        var updateRes = await client.PutAsJsonAsync($"/api/Zinute/{created.Id}", new { tekstas = "Updated" });
        Assert.Equal(HttpStatusCode.NoContent, updateRes.StatusCode);

        var getRes = await client.GetAsync($"/api/Zinute/{created.Id}");
        Assert.Equal(HttpStatusCode.OK, getRes.StatusCode);
        var fetched = await getRes.Content.ReadFromJsonAsync<Zinute>();
        Assert.NotNull(fetched);
        Assert.Equal("Updated", fetched!.Tekstas);

        var delRes = await client.DeleteAsync($"/api/Zinute/{created.Id}");
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
}
