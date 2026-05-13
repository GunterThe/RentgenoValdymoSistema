using System.Net;
using System.Net.Http;
using System.Net.Http.Json;
using System.Net.Http.Headers;
using System.IO;
using Backend.Models;
using Backend.Tests.Testing;
using Microsoft.EntityFrameworkCore;

namespace Backend.Tests.Controllers;

public sealed class PrisegtasFailasControllerTests : IClassFixture<CustomWebApplicationFactory>
{
    private readonly CustomWebApplicationFactory _factory;

    public PrisegtasFailasControllerTests(CustomWebApplicationFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task Create_Works_For_Authorized_User()
    {
        await _factory.ResetDatabaseAsync();
        var client = _factory.CreateClient().AsUser(Guid.NewGuid());

        var id = Guid.NewGuid();
        var createRes = await client.PostAsJsonAsync("/api/PrisegtasFailas", new
        {
            id,
            zingsnisId = (int?)null,
            zingsnisTemplateId = (int?)null,
            failoPav = "a.png",
            dydis = 123,
            nuoroda = (string?)null,
            sukurimoLaikas = DateTime.UtcNow,
        });

        Assert.Equal(HttpStatusCode.Created, createRes.StatusCode);
        var created = await createRes.Content.ReadFromJsonAsync<PrisegtasFailas>();
        Assert.NotNull(created);
        Assert.Equal(id, created!.Id);
    }

    [Fact]
    public async Task GetById_Works_For_Authorized_User()
    {
        await _factory.ResetDatabaseAsync();
        var client = _factory.CreateClient().AsUser(Guid.NewGuid());

        var id = Guid.NewGuid();
        await client.PostAsJsonAsync("/api/PrisegtasFailas", new
        {
            id,
            zingsnisId = (int?)null,
            zingsnisTemplateId = (int?)null,
            failoPav = "a.png",
            dydis = 123,
            nuoroda = (string?)null,
            sukurimoLaikas = DateTime.UtcNow,
        });

        var get = await client.GetAsync($"/api/PrisegtasFailas/{id}");
        Assert.Equal(HttpStatusCode.OK, get.StatusCode);
    }

    [Fact]
    public async Task Update_Works_For_Authorized_User()
    {
        await _factory.ResetDatabaseAsync();
        var client = _factory.CreateClient().AsUser(Guid.NewGuid());

        var id = Guid.NewGuid();
        await client.PostAsJsonAsync("/api/PrisegtasFailas", new
        {
            id,
            zingsnisId = (int?)null,
            zingsnisTemplateId = (int?)null,
            failoPav = "a.png",
            dydis = 123,
            nuoroda = (string?)null,
            sukurimoLaikas = DateTime.UtcNow,
        });

        var updateRes = await client.PutAsJsonAsync($"/api/PrisegtasFailas/{id}", new
        {
            id,
            zingsnisId = (int?)null,
            zingsnisTemplateId = (int?)null,
            failoPav = "b.png",
            dydis = 456,
            nuoroda = (string?)null,
            sukurimoLaikas = DateTime.UtcNow,
        });
        Assert.Equal(HttpStatusCode.NoContent, updateRes.StatusCode);

        var get2 = await client.GetAsync($"/api/PrisegtasFailas/{id}");
        var updated = await get2.Content.ReadFromJsonAsync<PrisegtasFailas>();
        Assert.NotNull(updated);
        Assert.Equal("b.png", updated!.FailoPav);
    }

    [Fact]
    public async Task Delete_Works_For_Authorized_User()
    {
        await _factory.ResetDatabaseAsync();
        var client = _factory.CreateClient().AsUser(Guid.NewGuid());

        var id = Guid.NewGuid();
        await client.PostAsJsonAsync("/api/PrisegtasFailas", new
        {
            id,
            zingsnisId = (int?)null,
            zingsnisTemplateId = (int?)null,
            failoPav = "a.png",
            dydis = 123,
            nuoroda = (string?)null,
            sukurimoLaikas = DateTime.UtcNow,
        });

        var del = await client.DeleteAsync($"/api/PrisegtasFailas/{id}");
        Assert.Equal(HttpStatusCode.NoContent, del.StatusCode);

        var getDeleted = await client.GetAsync($"/api/PrisegtasFailas/{id}");
        Assert.Equal(HttpStatusCode.NotFound, getDeleted.StatusCode);
    }

    [Fact]
    public async Task GetByZingsnis_Returns_Only_Matching()
    {
        await _factory.ResetDatabaseAsync();

        Guid userId = Guid.NewGuid();
        int zingsnisId = 0;
        Guid fileId = Guid.NewGuid();

        await _factory.WithDbContextAsync(async db =>
        {
            var user = new Naudotojas
            {
                Id = userId,
                Vardas = "V",
                Pavarde = "P",
                GimimoData = new DateTime(2000, 1, 1),
                Adminas = false,
                SuperAdminas = false,
                PrisijungimoId = "u",
                PasswordHash = BCrypt.Net.BCrypt.HashPassword("pass"),
                MustChangePassword = false,
            };
            db.Naudotojai.Add(user);

            var lok = new Lokacija { Pavadinimas = "L" };
            db.Lokacijos.Add(lok);
            await db.SaveChangesAsync();

            var irasas = new Irasas
            {
                IdDokumento = "doc",
                Pavadinimas = "irasas",
                LokacijaId = lok.Id,
                Pradzia = DateTime.UtcNow,
                Statusas = "Nepradėtas",
            };
            db.Irasai.Add(irasas);

            var testas = new Testas { Testotekstas = "T" };
            db.Testai.Add(testas);
            await db.SaveChangesAsync();

            var link = new TestasIrasas { Testasid = testas.Id, Irasasid = irasas.Id, Eile = 1 };
            db.TestasIrasai.Add(link);

            var tpl = new ZingsnisTemplate
            {
                Pavadinimas = "Z",
                Aprasymas = "A",
                TestasId = testas.Id,
                Eile = 1,
                KomentarasPrivalomas = false,
                NuotraukaPrivaloma = false,
            };
            db.ZingsnisTemplate.Add(tpl);
            await db.SaveChangesAsync();

            var z = new Zingsnis
            {
                Komentaras = "c",
                CompletedAt = null,
                TestasIrasasId = link.Id,
                ZingsnisTemplateId = tpl.Id,
                CompletedByUserId = userId,
            };
            db.Zingsniai.Add(z);
            await db.SaveChangesAsync();

            zingsnisId = z.Id;

            db.PrisegtiFailai.Add(new PrisegtasFailas
            {
                Id = fileId,
                ZingsnisId = zingsnisId,
                FailoPav = "x.jpg",
                Dydis = 1,
                Nuoroda = null,
                SukurimoLaikas = DateTime.UtcNow,
            });
            db.PrisegtiFailai.Add(new PrisegtasFailas
            {
                Id = Guid.NewGuid(),
                ZingsnisId = null,
                FailoPav = "y.jpg",
                Dydis = 1,
                Nuoroda = null,
                SukurimoLaikas = DateTime.UtcNow,
            });

            await db.SaveChangesAsync();
        });

        var client = _factory.CreateClient();
        var res = await client.GetAsync($"/api/PrisegtasFailas/byZingsnis/{zingsnisId}");
        Assert.Equal(HttpStatusCode.OK, res.StatusCode);

        var list = await res.Content.ReadFromJsonAsync<List<PrisegtasFailas>>();
        Assert.NotNull(list);
        Assert.Single(list!);
        Assert.Equal(fileId, list[0].Id);
    }

    [Fact]
    public async Task Upload_Works_And_File_Can_Be_Fetched_And_Downloaded()
    {
        await _factory.ResetDatabaseAsync();

        var userId = Guid.NewGuid();
        var zingsnisId = 0;

        await _factory.WithDbContextAsync(async db =>
        {
            var user = new Naudotojas
            {
                Id = userId,
                Vardas = "V",
                Pavarde = "P",
                GimimoData = new DateTime(2000, 1, 1),
                Adminas = false,
                SuperAdminas = false,
                PrisijungimoId = "u",
                PasswordHash = BCrypt.Net.BCrypt.HashPassword("pass"),
                MustChangePassword = false,
            };
            db.Naudotojai.Add(user);

            var lok = new Lokacija { Pavadinimas = "L" };
            db.Lokacijos.Add(lok);
            await db.SaveChangesAsync();

            var irasas = new Irasas
            {
                IdDokumento = "doc",
                Pavadinimas = "irasas",
                LokacijaId = lok.Id,
                Pradzia = DateTime.UtcNow,
                Statusas = "Nepradėtas",
            };
            db.Irasai.Add(irasas);

            var testas = new Testas { Testotekstas = "T" };
            db.Testai.Add(testas);
            await db.SaveChangesAsync();

            var link = new TestasIrasas { Testasid = testas.Id, Irasasid = irasas.Id, Eile = 1 };
            db.TestasIrasai.Add(link);

            var tpl = new ZingsnisTemplate
            {
                Pavadinimas = "Z",
                Aprasymas = "A",
                TestasId = testas.Id,
                Eile = 1,
                KomentarasPrivalomas = false,
                NuotraukaPrivaloma = false,
            };
            db.ZingsnisTemplate.Add(tpl);
            await db.SaveChangesAsync();

            var z = new Zingsnis
            {
                Komentaras = "c",
                CompletedAt = null,
                TestasIrasasId = link.Id,
                ZingsnisTemplateId = tpl.Id,
                CompletedByUserId = userId,
            };
            db.Zingsniai.Add(z);
            await db.SaveChangesAsync();
            zingsnisId = z.Id;
        });

        var client = _factory.CreateClient().AsUser(userId);

        var bytes = new byte[] { 1, 2, 3, 4, 5 };
        using var content = new MultipartFormDataContent();
        using var fileContent = new ByteArrayContent(bytes);
        fileContent.Headers.ContentType = new MediaTypeHeaderValue("image/png");
        content.Add(fileContent, "file", "test.png");

        var uploadRes = await client.PostAsync($"/api/PrisegtasFailas/upload/{zingsnisId}", content);
        Assert.Equal(HttpStatusCode.Created, uploadRes.StatusCode);

        var created = await uploadRes.Content.ReadFromJsonAsync<PrisegtasFailas>();
        Assert.NotNull(created);
        Assert.Equal(zingsnisId, created!.ZingsnisId);
        Assert.False(string.IsNullOrWhiteSpace(created.Nuoroda));

        try
        {
            var fileRes = await client.GetAsync($"/api/PrisegtasFailas/file/{created.Id}");
            Assert.Equal(HttpStatusCode.OK, fileRes.StatusCode);
            Assert.NotNull(fileRes.Content.Headers.ContentType);

            var downloadedBytes = await fileRes.Content.ReadAsByteArrayAsync();
            Assert.Equal(bytes, downloadedBytes);

            var dlRes = await client.GetAsync($"/api/PrisegtasFailas/download/{created.Id}");
            Assert.Equal(HttpStatusCode.OK, dlRes.StatusCode);
        }
        finally
        {
            await client.DeleteAsync($"/api/PrisegtasFailas/{created.Id}");
        }
    }

    [Fact]
    public async Task Upload_Returns_BadRequest_When_File_Is_Empty()
    {
        await _factory.ResetDatabaseAsync();

        var client = _factory.CreateClient().AsUser(Guid.NewGuid());

        using var content = new MultipartFormDataContent();
        using var fileContent = new ByteArrayContent(Array.Empty<byte>());
        fileContent.Headers.ContentType = new MediaTypeHeaderValue("application/octet-stream");
        content.Add(fileContent, "file", "empty.bin");

        var uploadRes = await client.PostAsync("/api/PrisegtasFailas/upload/1", content);
        Assert.Equal(HttpStatusCode.BadRequest, uploadRes.StatusCode);
    }

    [Fact]
    public async Task UploadTemplateImage_Returns_BadRequest_When_File_Is_Not_Image()
    {
        await _factory.ResetDatabaseAsync();

        var client = _factory.CreateClient().AsAdmin();

        using var content = new MultipartFormDataContent();
        using var fileContent = new ByteArrayContent(new byte[] { 1, 2, 3 });
        fileContent.Headers.ContentType = new MediaTypeHeaderValue("text/plain");
        content.Add(fileContent, "file", "not-image.txt");

        var res = await client.PostAsync("/api/PrisegtasFailas/uploadTemplate/1", content);
        Assert.Equal(HttpStatusCode.BadRequest, res.StatusCode);
    }

    [Fact]
    public async Task UploadTemplateImage_Returns_NotFound_When_Template_Does_Not_Exist()
    {
        await _factory.ResetDatabaseAsync();

        var client = _factory.CreateClient().AsAdmin();

        using var content = new MultipartFormDataContent();
        using var fileContent = new ByteArrayContent(new byte[] { 1, 2, 3 });
        fileContent.Headers.ContentType = new MediaTypeHeaderValue("image/png");
        content.Add(fileContent, "file", "img.png");

        var res = await client.PostAsync("/api/PrisegtasFailas/uploadTemplate/999", content);
        Assert.Equal(HttpStatusCode.NotFound, res.StatusCode);
    }

    [Fact]
    public async Task UploadTemplateImage_Replaces_Existing_Image_For_Template()
    {
        await _factory.ResetDatabaseAsync();

        int templateId = 0;
        await _factory.WithDbContextAsync(async db =>
        {
            var testas = new Testas { Testotekstas = "T" };
            db.Testai.Add(testas);
            await db.SaveChangesAsync();

            var tpl = new ZingsnisTemplate
            {
                Pavadinimas = "Z",
                Aprasymas = "A",
                TestasId = testas.Id,
                Eile = 1,
                KomentarasPrivalomas = false,
                NuotraukaPrivaloma = false,
            };
            db.ZingsnisTemplate.Add(tpl);
            await db.SaveChangesAsync();
            templateId = tpl.Id;
        });

        var client = _factory.CreateClient().AsAdmin();

        async Task<PrisegtasFailas> UploadAsync(byte[] payload, string name)
        {
            using var content = new MultipartFormDataContent();
            using var fileContent = new ByteArrayContent(payload);
            fileContent.Headers.ContentType = new MediaTypeHeaderValue("image/png");
            content.Add(fileContent, "file", name);

            var res = await client.PostAsync($"/api/PrisegtasFailas/uploadTemplate/{templateId}", content);
            Assert.Equal(HttpStatusCode.Created, res.StatusCode);
            var created = await res.Content.ReadFromJsonAsync<PrisegtasFailas>();
            Assert.NotNull(created);
            return created!;
        }

        var first = await UploadAsync(new byte[] { 1, 2, 3 }, "first.png");
        var firstPath = first.Nuoroda;

        var second = await UploadAsync(new byte[] { 9, 8, 7 }, "second.png");
        Assert.NotEqual(first.Id, second.Id);

        await _factory.WithDbContextAsync(async db =>
        {
            var items = await db.PrisegtiFailai.Where(p => p.ZingsnisTemplateId == templateId).ToListAsync();
            Assert.Single(items);
            Assert.Equal(second.Id, items[0].Id);
        });

        if (!string.IsNullOrWhiteSpace(firstPath))
        {
            var abs = Path.Combine(Directory.GetCurrentDirectory(), firstPath);
            Assert.False(System.IO.File.Exists(abs));
        }

        await client.DeleteAsync($"/api/PrisegtasFailas/{second.Id}");
    }
}
