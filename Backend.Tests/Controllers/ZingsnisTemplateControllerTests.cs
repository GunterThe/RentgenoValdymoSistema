using System.Net;
using System.Net.Http.Json;
using Backend.Models;
using Backend.Tests.Testing;

namespace Backend.Tests.Controllers;

public sealed class ZingsnisTemplateControllerTests : IClassFixture<CustomWebApplicationFactory>
{
    private readonly CustomWebApplicationFactory _factory;

    public ZingsnisTemplateControllerTests(CustomWebApplicationFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task Create_Get_Update_Delete_Works_For_Admin()
    {
        await _factory.ResetDatabaseAsync();
        var client = _factory.CreateClient().AsAdmin();

        var testas = new Testas { Testotekstas = "T" };
        await _factory.WithDbContextAsync(async db =>
        {
            db.Testai.Add(testas);
            await db.SaveChangesAsync();
        });

        var create1 = await client.PostAsJsonAsync("/api/ZingsnisTemplate", new
        {
            pavadinimas = "P1",
            aprasymas = "A1",
            testasId = testas.Id,
            komentarasPrivalomas = false,
            nuotraukaPrivaloma = false,
        });
        Assert.Equal(HttpStatusCode.Created, create1.StatusCode);
        var tpl1 = await create1.Content.ReadFromJsonAsync<ZingsnisTemplate>();
        Assert.NotNull(tpl1);
        Assert.True(tpl1!.Id > 0);
        Assert.Equal(1, tpl1.Eile);

        var create2 = await client.PostAsJsonAsync("/api/ZingsnisTemplate", new
        {
            pavadinimas = "P2",
            aprasymas = "A2",
            testasId = testas.Id,
            komentarasPrivalomas = true,
            nuotraukaPrivaloma = false,
        });
        Assert.Equal(HttpStatusCode.Created, create2.StatusCode);
        var tpl2 = await create2.Content.ReadFromJsonAsync<ZingsnisTemplate>();
        Assert.NotNull(tpl2);
        Assert.Equal(2, tpl2!.Eile);

        var get2 = await client.GetAsync($"/api/ZingsnisTemplate/{tpl2.Id}");
        Assert.Equal(HttpStatusCode.OK, get2.StatusCode);

        var update = await client.PutAsJsonAsync($"/api/ZingsnisTemplate/{tpl2.Id}", new
        {
            id = tpl2.Id,
            pavadinimas = "P2-upd",
            aprasymas = "A2-upd",
            testasId = testas.Id,
            eile = tpl2.Eile,
            komentarasPrivalomas = tpl2.KomentarasPrivalomas,
            nuotraukaPrivaloma = tpl2.NuotraukaPrivaloma,
        });
        Assert.Equal(HttpStatusCode.NoContent, update.StatusCode);

        var getUpd = await client.GetAsync($"/api/ZingsnisTemplate/{tpl2.Id}");
        var updated = await getUpd.Content.ReadFromJsonAsync<ZingsnisTemplate>();
        Assert.NotNull(updated);
        Assert.Equal("P2-upd", updated!.Pavadinimas);

        var del = await client.DeleteAsync($"/api/ZingsnisTemplate/{tpl1.Id}");
        Assert.Equal(HttpStatusCode.NoContent, del.StatusCode);

        var getDeleted = await client.GetAsync($"/api/ZingsnisTemplate/{tpl1.Id}");
        Assert.Equal(HttpStatusCode.NotFound, getDeleted.StatusCode);
    }
}
