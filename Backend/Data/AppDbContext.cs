using Backend.Models;
using Microsoft.EntityFrameworkCore;

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

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            modelBuilder.Entity<TestasIrasas>()
                .HasKey(t => new { t.Testasid, t.Irasasid });

            modelBuilder.Entity<PrisegtasFailas>()
                .HasOne(p => p.Irasas)
                .WithMany()
                .HasForeignKey(p => p.Irasasid)
                .OnDelete(DeleteBehavior.Cascade);
        }
    }
}
