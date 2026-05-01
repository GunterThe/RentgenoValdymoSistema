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

    [Fact]
    public async Task Admin_Can_Create_And_Delete_Link_User_Can_Read_And_Update_Own()
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

        var adminClient = _factory.CreateClient().AsAdmin();
        var createRes = await adminClient.PostAsJsonAsync("/api/NaudotojasZinute", new
        {
            naudotojasId = userId,
            zinuteId = zinute.Id,
        });
        Assert.Equal(HttpStatusCode.Created, createRes.StatusCode);

        var userClient = _factory.CreateClient().AsUser(userId);

        var myRes = await userClient.GetAsync("/api/NaudotojasZinute/my");
        Assert.Equal(HttpStatusCode.OK, myRes.StatusCode);
        var inbox = await myRes.Content.ReadFromJsonAsync<List<NaudotojasZinuteController.InboxItemDto>>();
        Assert.NotNull(inbox);
        Assert.NotEmpty(inbox!);

        var updateRes = await userClient.PutAsJsonAsync($"/api/NaudotojasZinute/{userId}/{zinute.Id}", new
        {
            perskaityta = true,
        });
        Assert.Equal(HttpStatusCode.NoContent, updateRes.StatusCode);

        var delRes = await adminClient.DeleteAsync($"/api/NaudotojasZinute/{userId}/{zinute.Id}");
        Assert.Equal(HttpStatusCode.NoContent, delRes.StatusCode);
    }
}
