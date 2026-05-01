using System.Net;
using System.Net.Http.Json;
using Backend.Models;
using Backend.Tests.Testing;

namespace Backend.Tests.Controllers;

public sealed class LokacijaControllerTests : IClassFixture<CustomWebApplicationFactory>
{
    private readonly CustomWebApplicationFactory _factory;

    public LokacijaControllerTests(CustomWebApplicationFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task Crud_Works_For_Admin()
    {
        await _factory.ResetDatabaseAsync();
        var client = _factory.CreateClient().AsAdmin();

        // Create
        var createRes = await client.PostAsJsonAsync("/api/Lokacija", new { pavadinimas = "Test Lokacija" });
        Assert.Equal(HttpStatusCode.Created, createRes.StatusCode);
        var created = await createRes.Content.ReadFromJsonAsync<Lokacija>();
        Assert.NotNull(created);
        Assert.True(created!.Id > 0);
        Assert.Equal("Test Lokacija", created.Pavadinimas);

        // Read
        var getRes = await client.GetAsync($"/api/Lokacija/{created.Id}");
        Assert.Equal(HttpStatusCode.OK, getRes.StatusCode);
        var fetched = await getRes.Content.ReadFromJsonAsync<Lokacija>();
        Assert.NotNull(fetched);
        Assert.Equal(created.Id, fetched!.Id);

        // Update
        var updateRes = await client.PutAsJsonAsync($"/api/Lokacija/{created.Id}", new { id = created.Id, pavadinimas = "Updated" });
        Assert.Equal(HttpStatusCode.NoContent, updateRes.StatusCode);

        var getRes2 = await client.GetAsync($"/api/Lokacija/{created.Id}");
        var fetched2 = await getRes2.Content.ReadFromJsonAsync<Lokacija>();
        Assert.NotNull(fetched2);
        Assert.Equal("Updated", fetched2!.Pavadinimas);

        // Delete
        var delRes = await client.DeleteAsync($"/api/Lokacija/{created.Id}");
        Assert.Equal(HttpStatusCode.NoContent, delRes.StatusCode);

        var getRes3 = await client.GetAsync($"/api/Lokacija/{created.Id}");
        Assert.Equal(HttpStatusCode.NotFound, getRes3.StatusCode);
    }

    [Fact]
    public async Task Delete_Returns_BadRequest_When_InUse()
    {
        await _factory.ResetDatabaseAsync();
        var client = _factory.CreateClient().AsAdmin();

        int lokacijaId = 0;
        await _factory.WithDbContextAsync(async db =>
        {
            var lok = new Lokacija { Pavadinimas = "InUse" };
            db.Lokacijos.Add(lok);
            await db.SaveChangesAsync();

            db.Irasai.Add(new Irasas
            {
                IdDokumento = "doc-1",
                Pavadinimas = "irasas",
                LokacijaId = lok.Id,
                Pradzia = DateTime.UtcNow,
                Statusas = "Nepradėtas",
            });
            await db.SaveChangesAsync();
            lokacijaId = lok.Id;
        });

        var delRes = await client.DeleteAsync($"/api/Lokacija/{lokacijaId}");
        Assert.Equal(HttpStatusCode.BadRequest, delRes.StatusCode);
    }
}
