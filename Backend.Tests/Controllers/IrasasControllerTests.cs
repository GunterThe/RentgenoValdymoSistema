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

    private async Task<Lokacija> CreateLokacijaAsync(string pavadinimas = "L")
    {
        var lokacija = new Lokacija { Pavadinimas = pavadinimas };
        await _factory.WithDbContextAsync(async db =>
        {
            db.Lokacijos.Add(lokacija);
            await db.SaveChangesAsync();
        });
        return lokacija;
    }

    private static object CreatePayload(int lokacijaId) => new
    {
        idDokumento = "doc-123",
        pavadinimas = "Pavadinimas",
        lokacijaId,
        sablonasId = (int?)null,
    };

    [Fact]
    public async Task Create_Works_For_Admin_When_No_Sablonas()
    {
        await _factory.ResetDatabaseAsync();
        var client = _factory.CreateClient().AsAdmin();

        var lokacija = await CreateLokacijaAsync();

        var createRes = await client.PostAsJsonAsync("/api/Irasas", CreatePayload(lokacija.Id));

        Assert.Equal(HttpStatusCode.Created, createRes.StatusCode);
        var created = await createRes.Content.ReadFromJsonAsync<Irasas>();
        Assert.NotNull(created);
        Assert.True(created!.Id > 0);
        Assert.Equal(lokacija.Id, created.LokacijaId);
    }

    [Fact]
    public async Task GetById_Works_For_Admin()
    {
        await _factory.ResetDatabaseAsync();
        var client = _factory.CreateClient().AsAdmin();

        var lokacija = await CreateLokacijaAsync();
        var createRes = await client.PostAsJsonAsync("/api/Irasas", CreatePayload(lokacija.Id));
        var created = await createRes.Content.ReadFromJsonAsync<Irasas>();
        Assert.NotNull(created);

        var getRes = await client.GetAsync($"/api/Irasas/{created!.Id}");
        Assert.Equal(HttpStatusCode.OK, getRes.StatusCode);
    }

    [Fact]
    public async Task GetAll_Returns_Items()
    {
        await _factory.ResetDatabaseAsync();
        var client = _factory.CreateClient().AsAdmin();

        var lokacija = await CreateLokacijaAsync();
        await client.PostAsJsonAsync("/api/Irasas", CreatePayload(lokacija.Id));

        var listRes = await client.GetAsync("/api/Irasas");
        Assert.Equal(HttpStatusCode.OK, listRes.StatusCode);
        var list = await listRes.Content.ReadFromJsonAsync<List<Irasas>>();
        Assert.NotNull(list);
        Assert.True(list!.Count >= 1);
    }

    [Fact]
    public async Task Update_Works_For_Admin()
    {
        await _factory.ResetDatabaseAsync();
        var client = _factory.CreateClient().AsAdmin();

        var lokacija = await CreateLokacijaAsync();
        var createRes = await client.PostAsJsonAsync("/api/Irasas", CreatePayload(lokacija.Id));
        var created = await createRes.Content.ReadFromJsonAsync<Irasas>();
        Assert.NotNull(created);

        var updatePayload = new
        {
            id = created!.Id,
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
    }

    [Fact]
    public async Task Delete_Works_For_Admin()
    {
        await _factory.ResetDatabaseAsync();
        var client = _factory.CreateClient().AsAdmin();

        var lokacija = await CreateLokacijaAsync();
        var createRes = await client.PostAsJsonAsync("/api/Irasas", CreatePayload(lokacija.Id));
        var created = await createRes.Content.ReadFromJsonAsync<Irasas>();
        Assert.NotNull(created);

        var delRes = await client.DeleteAsync($"/api/Irasas/{created!.Id}");
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
