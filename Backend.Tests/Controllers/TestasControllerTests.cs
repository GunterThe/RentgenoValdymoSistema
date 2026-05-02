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

    [Fact]
    public async Task Get_And_Delete_Work_With_Seeded_Data()
    {
        await _factory.ResetDatabaseAsync();

        var testas = new Testas { Testotekstas = "T" };
        await _factory.WithDbContextAsync(async db =>
        {
            db.Testai.Add(testas);
            await db.SaveChangesAsync();
        });

        var userClient = _factory.CreateClient().AsUser(Guid.NewGuid());

        var getAll = await userClient.GetAsync("/api/Testas");
        Assert.Equal(HttpStatusCode.OK, getAll.StatusCode);
        var list = await getAll.Content.ReadFromJsonAsync<List<Testas>>();
        Assert.NotNull(list);
        Assert.Contains(list!, t => t.Id == testas.Id);

        var get = await userClient.GetAsync($"/api/Testas/{testas.Id}");
        Assert.Equal(HttpStatusCode.OK, get.StatusCode);

        var adminClient = _factory.CreateClient().AsAdmin();
        var del = await adminClient.DeleteAsync($"/api/Testas/{testas.Id}");
        Assert.Equal(HttpStatusCode.NoContent, del.StatusCode);

        var getDeleted = await userClient.GetAsync($"/api/Testas/{testas.Id}");
        Assert.Equal(HttpStatusCode.NotFound, getDeleted.StatusCode);
    }
}
