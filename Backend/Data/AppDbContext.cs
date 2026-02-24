using Backend.Models;
using Microsoft.EntityFrameworkCore;
using Npgsql.EntityFrameworkCore.PostgreSQL;
using NpgsqlTypes;
using Npgsql;

namespace Backend.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
        {
        }

        public DbSet<Irasas> Irasai { get; set; } = null!;
        public DbSet<Naudotojas> Naudotojai { get; set; } = null!;
        public DbSet<Testas> Testai { get; set; } = null!;
        public DbSet<TestasIrasas> TestasIrasai { get; set; } = null!;
        public DbSet<PrisegtasFailas> PrisegtiFailai { get; set; } = null!;
        public DbSet<RefreshToken> RefreshTokens { get; set; } = null!;
        public DbSet<Zingsnis> Zingsniai { get; set; } = null!;

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            modelBuilder.HasPostgresEnum<TestoTipas>();

            modelBuilder.Entity<Testas>()
                .Property(t => t.Tipas)
                .HasColumnType("public.testotipas");

            modelBuilder.Entity<TestasIrasas>()
                .HasKey(t => new { t.Testasid, t.Irasasid });

            modelBuilder.Entity<PrisegtasFailas>()
                .HasOne(p => p.Zingsnis)
                .WithMany()
                .HasForeignKey(p => p.ZingsnisId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Zingsnis>()
                .HasOne(z => z.Testas)
                .WithMany()
                .HasForeignKey(z => z.TestasId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Testas>(entity =>
            {
                entity.ToTable("testas");
                
                entity.Property(e => e.Tipas)
                    .HasColumnType("public.testotipas") 
                    .HasConversion<string>();
            });
        }
    }
}
