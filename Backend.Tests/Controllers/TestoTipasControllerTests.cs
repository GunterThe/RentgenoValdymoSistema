using System.Net;
using System.Net.Http.Json;
using Backend.Controllers;
using Backend.Tests.Testing;

namespace Backend.Tests.Controllers;

public sealed class TestoTipasControllerTests : IClassFixture<CustomWebApplicationFactory>
{
    private readonly CustomWebApplicationFactory _factory;

    public TestoTipasControllerTests(CustomWebApplicationFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task GetAll_Returns_Items()
    {
        await _factory.ResetDatabaseAsync();
        var client = _factory.CreateClient();

        var res = await client.GetAsync("/api/TestoTipas");
        Assert.Equal(HttpStatusCode.OK, res.StatusCode);

        var items = await res.Content.ReadFromJsonAsync<List<TestoTipasController.TestoTipasItem>>();
        Assert.NotNull(items);
        Assert.NotEmpty(items!);
        Assert.All(items!, i => Assert.False(string.IsNullOrWhiteSpace(i.Name)));
    }
}
