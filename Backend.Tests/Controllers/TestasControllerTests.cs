using System.Net;
using System.Net.Http.Json;
using Backend.Models;
using Backend.Tests.Testing;

namespace Backend.Tests.Controllers;

public sealed class TestasControllerTests : IClassFixture<CustomWebApplicationFactory>
{
    private readonly CustomWebApplicationFactory _factory;

    public TestasControllerTests(CustomWebApplicationFactory factory)
    {
        _factory = factory;
    }

    private async Task<int> SeedTestasAsync()
    {
        await _factory.ResetDatabaseAsync();

        var testas = new Testas { Testotekstas = "T" };
        await _factory.WithDbContextAsync(async db =>
        {
            db.Testai.Add(testas);
            await db.SaveChangesAsync();
        });

        return testas.Id;
    }

    [Fact]
    public async Task GetAll_Returns_Seeded_Item()
    {
        var testasId = await SeedTestasAsync();
        var userClient = _factory.CreateClient().AsUser(Guid.NewGuid());

        var getAll = await userClient.GetAsync("/api/Testas");
        Assert.Equal(HttpStatusCode.OK, getAll.StatusCode);
        var list = await getAll.Content.ReadFromJsonAsync<List<Testas>>();
        Assert.NotNull(list);
        Assert.Contains(list!, t => t.Id == testasId);
    }

    [Fact]
    public async Task GetById_Works_With_Seeded_Data()
    {
        var testasId = await SeedTestasAsync();
        var userClient = _factory.CreateClient().AsUser(Guid.NewGuid());

        var get = await userClient.GetAsync($"/api/Testas/{testasId}");
        Assert.Equal(HttpStatusCode.OK, get.StatusCode);
    }

    [Fact]
    public async Task Delete_Works_For_Admin()
    {
        var testasId = await SeedTestasAsync();
        var userClient = _factory.CreateClient().AsUser(Guid.NewGuid());

        var adminClient = _factory.CreateClient().AsAdmin();
        var del = await adminClient.DeleteAsync($"/api/Testas/{testasId}");
        Assert.Equal(HttpStatusCode.NoContent, del.StatusCode);

        var getDeleted = await userClient.GetAsync($"/api/Testas/{testasId}");
        Assert.Equal(HttpStatusCode.NotFound, getDeleted.StatusCode);
    }
}
