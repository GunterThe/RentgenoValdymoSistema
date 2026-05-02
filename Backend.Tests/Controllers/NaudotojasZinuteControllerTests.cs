using System.Net;
using System.Net.Http.Json;
using Backend.Controllers;
using Backend.Models;
using Backend.Tests.Testing;

namespace Backend.Tests.Controllers;

public sealed class NaudotojasZinuteControllerTests : IClassFixture<CustomWebApplicationFactory>
{
    private readonly CustomWebApplicationFactory _factory;

    public NaudotojasZinuteControllerTests(CustomWebApplicationFactory factory)
    {
        _factory = factory;
    }

    private async Task<(Guid userId, int zinuteId)> SeedUserAndZinuteAsync()
    {
        await _factory.ResetDatabaseAsync();
        var userId = Guid.NewGuid();
        var zinute = new Zinute { Tekstas = "Msg" };

        await _factory.WithDbContextAsync(async db =>
        {
            db.Naudotojai.Add(new Naudotojas
            {
                Id = userId,
                Vardas = "U",
                Pavarde = "S",
                GimimoData = new DateTime(2000, 1, 1, 0, 0, 0, DateTimeKind.Utc),
                Adminas = false,
                PrisijungimoId = "u.s.001",
                PasswordHash = BCrypt.Net.BCrypt.HashPassword("secret1"),
                SuperAdminas = false,
                MustChangePassword = false,
            });

            db.Zinutes.Add(zinute);
            await db.SaveChangesAsync();
        });

        return (userId, zinute.Id);
    }

    [Fact]
    public async Task Admin_Can_Create_Link()
    {
        var (userId, zinuteId) = await SeedUserAndZinuteAsync();
        var adminClient = _factory.CreateClient().AsAdmin();
        var createRes = await adminClient.PostAsJsonAsync("/api/NaudotojasZinute", new
        {
            naudotojasId = userId,
            zinuteId,
        });
        Assert.Equal(HttpStatusCode.Created, createRes.StatusCode);
    }

    [Fact]
    public async Task User_Can_Read_My_Inbox()
    {
        var (userId, zinuteId) = await SeedUserAndZinuteAsync();
        var adminClient = _factory.CreateClient().AsAdmin();

        await adminClient.PostAsJsonAsync("/api/NaudotojasZinute", new { naudotojasId = userId, zinuteId });

        var userClient = _factory.CreateClient().AsUser(userId);

        var myRes = await userClient.GetAsync("/api/NaudotojasZinute/my");
        Assert.Equal(HttpStatusCode.OK, myRes.StatusCode);
        var inbox = await myRes.Content.ReadFromJsonAsync<List<NaudotojasZinuteController.InboxItemDto>>();
        Assert.NotNull(inbox);
        Assert.NotEmpty(inbox!);
    }

    [Fact]
    public async Task User_Can_Update_Own_Link()
    {
        var (userId, zinuteId) = await SeedUserAndZinuteAsync();
        var adminClient = _factory.CreateClient().AsAdmin();
        await adminClient.PostAsJsonAsync("/api/NaudotojasZinute", new { naudotojasId = userId, zinuteId });

        var userClient = _factory.CreateClient().AsUser(userId);

        var updateRes = await userClient.PutAsJsonAsync($"/api/NaudotojasZinute/{userId}/{zinuteId}", new
        {
            perskaityta = true,
        });
        Assert.Equal(HttpStatusCode.NoContent, updateRes.StatusCode);
    }

    [Fact]
    public async Task Admin_Can_Delete_Link()
    {
        var (userId, zinuteId) = await SeedUserAndZinuteAsync();
        var adminClient = _factory.CreateClient().AsAdmin();
        await adminClient.PostAsJsonAsync("/api/NaudotojasZinute", new { naudotojasId = userId, zinuteId });

        var delRes = await adminClient.DeleteAsync($"/api/NaudotojasZinute/{userId}/{zinuteId}");
        Assert.Equal(HttpStatusCode.NoContent, delRes.StatusCode);
    }
}
