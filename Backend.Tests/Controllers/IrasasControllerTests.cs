using System.Net;
using System.Net.Http.Json;
using System.Text;
using Backend.Models;
using Backend.Tests.Testing;
using Microsoft.EntityFrameworkCore;

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

    private async Task<Sablonas> CreateSablonasWithTestaisAsync(int testaiCount = 2)
    {
        var sablonas = new Sablonas { Pavadinimas = "S" };

        await _factory.WithDbContextAsync(async db =>
        {
            db.Sablonai.Add(sablonas);

            for (var i = 0; i < testaiCount; i++)
            {
                db.Testai.Add(new Testas { Testotekstas = $"T{i + 1}" });
            }

            await db.SaveChangesAsync();

            var testasIds = await db.Testai
                .AsNoTracking()
                .OrderBy(t => t.Id)
                .Select(t => t.Id)
                .Take(testaiCount)
                .ToListAsync();

            for (var i = 0; i < testasIds.Count; i++)
            {
                db.SablonasTestai.Add(new SablonasTestas
                {
                    Sablonasid = sablonas.Id,
                    Testasid = testasIds[i],
                });
            }

            await db.SaveChangesAsync();
        });

        return sablonas;
    }

    private static object CreatePayload(int lokacijaId) => new
    {
        idDokumento = "doc-123",
        pavadinimas = "Pavadinimas",
        lokacijaId,
        sablonasId = (int?)null,
    };

    private static object CreatePayload(int lokacijaId, int sablonasId) => new
    {
        idDokumento = "doc-123",
        pavadinimas = "Pavadinimas",
        lokacijaId,
        sablonasId,
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

    [Fact]
    public async Task Create_Rejects_Null_Request_Body()
    {
        await _factory.ResetDatabaseAsync();
        var client = _factory.CreateClient().AsAdmin();

        var res = await client.PostAsync(
            "/api/Irasas",
            new StringContent("null", Encoding.UTF8, "application/json"));

        Assert.Equal(HttpStatusCode.BadRequest, res.StatusCode);
    }

    [Theory]
    [InlineData(" ", "P", 1, "IdDokumento is required")]
    [InlineData("doc", "  ", 1, "Pavadinimas is required")]
    public async Task Create_Rejects_Required_Strings(string idDokumento, string pavadinimas, int lokacijaId, string expectedMessage)
    {
        await _factory.ResetDatabaseAsync();
        var client = _factory.CreateClient().AsAdmin();

        var lokacija = await CreateLokacijaAsync();

        var res = await client.PostAsJsonAsync("/api/Irasas", new
        {
            idDokumento,
            pavadinimas,
            lokacijaId = lokacijaId == 1 ? lokacija.Id : lokacijaId,
            sablonasId = (int?)null,
        });

        Assert.Equal(HttpStatusCode.BadRequest, res.StatusCode);
        var body = await res.Content.ReadFromJsonAsync<Dictionary<string, string>>();
        Assert.NotNull(body);
        Assert.Equal(expectedMessage, body!["message"]);
    }

    [Fact]
    public async Task Create_Rejects_LokacijaId_Required()
    {
        await _factory.ResetDatabaseAsync();
        var client = _factory.CreateClient().AsAdmin();

        var res = await client.PostAsJsonAsync("/api/Irasas", new
        {
            idDokumento = "doc",
            pavadinimas = "P",
            lokacijaId = 0,
            sablonasId = (int?)null,
        });

        Assert.Equal(HttpStatusCode.BadRequest, res.StatusCode);
        var body = await res.Content.ReadFromJsonAsync<Dictionary<string, string>>();
        Assert.NotNull(body);
        Assert.Equal("LokacijaId is required", body!["message"]);
    }

    [Fact]
    public async Task Create_Rejects_Sablonas_Does_Not_Exist()
    {
        await _factory.ResetDatabaseAsync();
        var client = _factory.CreateClient().AsAdmin();

        var lokacija = await CreateLokacijaAsync();
        var res = await client.PostAsJsonAsync("/api/Irasas", CreatePayload(lokacija.Id, sablonasId: 999999));

        Assert.Equal(HttpStatusCode.BadRequest, res.StatusCode);
        var body = await res.Content.ReadFromJsonAsync<Dictionary<string, string>>();
        Assert.NotNull(body);
        Assert.Equal("Sablonas does not exist", body!["message"]);
    }

    [Fact]
    public async Task Create_With_Sablonas_Creates_TestasIrasas_Links()
    {
        await _factory.ResetDatabaseAsync();
        var client = _factory.CreateClient().AsAdmin();

        var lokacija = await CreateLokacijaAsync();
        var sablonas = await CreateSablonasWithTestaisAsync(testaiCount: 2);

        var createRes = await client.PostAsJsonAsync("/api/Irasas", CreatePayload(lokacija.Id, sablonas.Id));

        Assert.Equal(HttpStatusCode.Created, createRes.StatusCode);
        var created = await createRes.Content.ReadFromJsonAsync<Irasas>();
        Assert.NotNull(created);

        await _factory.WithDbContextAsync(async db =>
        {
            var links = await db.TestasIrasai
                .AsNoTracking()
                .Where(ti => ti.Irasasid == created!.Id)
                .OrderBy(ti => ti.Eile)
                .ToListAsync();

            Assert.Equal(2, links.Count);
            Assert.Equal(1, links[0].Eile);
            Assert.Equal(2, links[1].Eile);
        });
    }

    [Fact]
    public async Task Update_Rejects_Id_Mismatch()
    {
        await _factory.ResetDatabaseAsync();
        var client = _factory.CreateClient().AsAdmin();

        var lokacija = await CreateLokacijaAsync();
        var createRes = await client.PostAsJsonAsync("/api/Irasas", CreatePayload(lokacija.Id));
        var created = await createRes.Content.ReadFromJsonAsync<Irasas>();
        Assert.NotNull(created);

        var updateRes = await client.PutAsJsonAsync($"/api/Irasas/{created!.Id}", new
        {
            id = created.Id + 1,
            idDokumento = created.IdDokumento,
            pavadinimas = created.Pavadinimas,
            pradzia = created.Pradzia,
            pabaiga = created.Pabaiga,
            statusas = created.Statusas,
            lokacijaId = created.LokacijaId,
        });

        Assert.Equal(HttpStatusCode.BadRequest, updateRes.StatusCode);
    }

    [Fact]
    public async Task Update_Returns_NotFound_When_Missing()
    {
        await _factory.ResetDatabaseAsync();
        var client = _factory.CreateClient().AsAdmin();

        var updateRes = await client.PutAsJsonAsync("/api/Irasas/999999", new
        {
            id = 999999,
            idDokumento = "doc",
            pavadinimas = "P",
            pradzia = DateTime.UtcNow,
            pabaiga = (DateTime?)null,
            statusas = "X",
            lokacijaId = 1,
        });

        Assert.Equal(HttpStatusCode.NotFound, updateRes.StatusCode);
    }

    [Fact]
    public async Task Delete_Returns_NotFound_When_Missing()
    {
        await _factory.ResetDatabaseAsync();
        var client = _factory.CreateClient().AsAdmin();

        var delRes = await client.DeleteAsync("/api/Irasas/999999");
        Assert.Equal(HttpStatusCode.NotFound, delRes.StatusCode);
    }
}
