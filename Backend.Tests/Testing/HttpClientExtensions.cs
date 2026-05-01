using System.Net.Http.Headers;

namespace Backend.Tests.Testing;

public static class HttpClientExtensions
{
    public static HttpClient AsAdmin(this HttpClient client)
    {
        client.DefaultRequestHeaders.Remove("X-Test-Admin");
        client.DefaultRequestHeaders.Add("X-Test-Admin", "true");
        return client;
    }

    public static HttpClient AsSuperAdmin(this HttpClient client)
    {
        client.DefaultRequestHeaders.Remove("X-Test-Admin");
        client.DefaultRequestHeaders.Remove("X-Test-SuperAdmin");
        client.DefaultRequestHeaders.Add("X-Test-Admin", "true");
        client.DefaultRequestHeaders.Add("X-Test-SuperAdmin", "true");
        return client;
    }

    public static HttpClient AsUser(this HttpClient client, Guid userId, bool admin = false, bool superAdmin = false)
    {
        client.DefaultRequestHeaders.Remove("X-Test-UserId");
        client.DefaultRequestHeaders.Remove("X-Test-Admin");
        client.DefaultRequestHeaders.Remove("X-Test-SuperAdmin");

        client.DefaultRequestHeaders.Add("X-Test-UserId", userId.ToString());
        client.DefaultRequestHeaders.Add("X-Test-Admin", admin ? "true" : "false");
        client.DefaultRequestHeaders.Add("X-Test-SuperAdmin", superAdmin ? "true" : "false");
        return client;
    }
}
