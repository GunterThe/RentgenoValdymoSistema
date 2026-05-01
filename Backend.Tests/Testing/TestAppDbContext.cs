using Backend.Data;
using Backend.Models;
using Microsoft.EntityFrameworkCore;

namespace Backend.Tests.Testing;

public sealed class TestAppDbContext : AppDbContext
{
    public TestAppDbContext(DbContextOptions<AppDbContext> options)
        : base(options)
    {
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // SQLite doesn't accept schema-qualified type names like "public.testotipas".
        // Keep production mapping in Backend, but override it for integration tests.
        modelBuilder.Entity<Testas>()
            .Property(t => t.Tipas)
            .HasColumnType("TEXT");
    }
}
