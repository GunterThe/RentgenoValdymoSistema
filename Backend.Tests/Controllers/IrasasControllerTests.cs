using System.Net;
using System.Net.Http.Json;
using Backend.Models;
using Backend.Tests.Testing;

namespace Backend.Tests.Controllers;

public sealed class IrasasControllerTests : IClassFixture<CustomWebApplicationFactory>
{
    private readonly CustomWebApplicationFactory _factory;

    public IrasasControllerTests(CustomWebApplicationFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task Crud_Works_For_Admin_When_No_Sablonas()
    {
        await _factory.ResetDatabaseAsync();
        var client = _factory.CreateClient().AsAdmin();

        var lokacija = new Lokacija { Pavadinimas = "L" };
        await _factory.WithDbContextAsync(async db =>
        {
            db.Lokacijos.Add(lokacija);
            await db.SaveChangesAsync();
        });

        // Create
        var createRes = await client.PostAsJsonAsync("/api/Irasas", new
        {
            idDokumento = "doc-123",
            pavadinimas = "Pavadinimas",
            lokacijaId = lokacija.Id,
            sablonasId = (int?)null,
        });

        Assert.Equal(HttpStatusCode.Created, createRes.StatusCode);
        var created = await createRes.Content.ReadFromJsonAsync<Irasas>();
        Assert.NotNull(created);
        Assert.True(created!.Id > 0);
        Assert.Equal(lokacija.Id, created.LokacijaId);

        // Read
        var getRes = await client.GetAsync($"/api/Irasas/{created.Id}");
        Assert.Equal(HttpStatusCode.OK, getRes.StatusCode);

        // List
        var listRes = await client.GetAsync("/api/Irasas");
        Assert.Equal(HttpStatusCode.OK, listRes.StatusCode);

        // Update
        var updatePayload = new
        {
            id = created.Id,
            idDokumento = created.IdDokumento,
            pavadinimas = "Updated",
            pradzia = created.Pradzia,
            pabaiga = created.Pabaiga,
            statusas = created.Statusas,
            lokacijaId = created.LokacijaId,
        };

        var updateRes = await client.PutAsJsonAsync($"/api/Irasas/{created.Id}", updatePayload);
        Assert.Equal(HttpStatusCode.NoContent, updateRes.StatusCode);

        var getRes2 = await client.GetAsync($"/api/Irasas/{created.Id}");
        var updated = await getRes2.Content.ReadFromJsonAsync<Irasas>();
        Assert.NotNull(updated);
        Assert.Equal("Updated", updated!.Pavadinimas);

        // Delete
        var delRes = await client.DeleteAsync($"/api/Irasas/{created.Id}");
        Assert.Equal(HttpStatusCode.NoContent, delRes.StatusCode);

        var getRes3 = await client.GetAsync($"/api/Irasas/{created.Id}");
        Assert.Equal(HttpStatusCode.NotFound, getRes3.StatusCode);
    }

    [Fact]
    public async Task Create_Rejects_Missing_Lokacija()
    {
        await _factory.ResetDatabaseAsync();
        var client = _factory.CreateClient().AsAdmin();

        var res = await client.PostAsJsonAsync("/api/Irasas", new
        {
            idDokumento = "doc-123",
            pavadinimas = "P",
            lokacijaId = 999999,
            sablonasId = (int?)null,
        });

        Assert.Equal(HttpStatusCode.BadRequest, res.StatusCode);
    }
}
