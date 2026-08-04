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
        public DbSet<ZingsnisTemplate> ZingsnisTemplate { get; set; } = null!;
        public DbSet<Lokacija> Lokacijos { get; set; } = null!;
        public DbSet<Sablonas> Sablonai { get; set; } = null!;
        public DbSet<SablonasTestas> SablonasTestai { get; set; } = null!;
        public DbSet<TestasIrasasPrivalomasZingsnisTemplate> TestasIrasasPrivalomiZingsniai { get; set; } = null!;
        public DbSet<Zinute> Zinutes { get; set; } = null!;
        public DbSet<NaudotojasZinute> NaudotojasZinute { get; set; } = null!;
        public DbSet<Row> Rows { get; set; } = null!;
        public DbSet<RowValue> RowValues { get; set; } = null!;
        public DbSet<RowIrasas> RowIrasai { get; set; } = null!;
        public DbSet<ColumnTemplate> ColumnTemplates { get; set; } = null!;
        public DbSet<ColumnValue> ColumnValues { get; set; } = null!;
        public DbSet<Header> Headers { get; set; } = null!;
        public DbSet<FAT> FATs { get; set; } = null!;
        public DbSet<FATRow> FATRows { get; set; } = null!;

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            modelBuilder.HasPostgresEnum<TestoTipas>();

            modelBuilder.Entity<RowIrasas>()
                .HasOne(ri => ri.Row)
                .WithMany(r => r.Irasas)
                .HasForeignKey(ri => ri.RowId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<RowIrasas>()
                .HasOne(ri => ri.Irasas)
                .WithMany(i => i.Rows)
                .HasForeignKey(ri => ri.IrasasId)
                .OnDelete(DeleteBehavior.Cascade);

            // `row_irasas` table uses an identity `id` primary key (see sql/create_tables.sql).
            // Use a unique index on (RowId, IrasasId) instead of a composite primary key.
            modelBuilder.Entity<RowIrasas>()
                .HasIndex(ri => new { ri.RowId, ri.IrasasId })
                .IsUnique();

            modelBuilder.Entity<SablonasTestas>()
                .HasKey(st => new { st.Sablonasid, st.Testasid });
            
            modelBuilder.Entity<SablonasTestas>()
                .HasOne(st => st.Sablonas)
                .WithMany(s => s.Testai)
                .HasForeignKey(st => st.Sablonasid)
                .OnDelete(DeleteBehavior.Cascade);
            
            modelBuilder.Entity<SablonasTestas>()
                .HasOne(st => st.Testas)
                .WithMany(t => t.Sablonai)
                .HasForeignKey(st => st.Testasid)
                .OnDelete(DeleteBehavior.Cascade);

            
            modelBuilder.Entity<FAT>()
                .HasKey(f => f.Id);

            modelBuilder.Entity<FATRow>()
                .HasKey(fr => new { fr.Fatid, fr.Rowid });

            modelBuilder.Entity<FATRow>()
                .HasOne(fr => fr.FAT)
                .WithMany(f => f.Rows)
                .HasForeignKey(fr => fr.Fatid)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<FATRow>()
                .HasOne(fr => fr.Row)
                .WithMany(r => r.FATRows)
                .HasForeignKey(fr => fr.Rowid)
                .OnDelete(DeleteBehavior.Cascade);


            modelBuilder.Entity<NaudotojasZinute>()
                .HasKey(nz => new { nz.Naudotojasid, nz.Zinuteid });
            
            modelBuilder.Entity<NaudotojasZinute>()
                .HasOne(nz => nz.Naudotojas)
                .WithMany(n => n.Zinutes)
                .HasForeignKey(nz => nz.Naudotojasid)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<NaudotojasZinute>()
                .HasOne(nz => nz.Zinute)
                .WithMany(z => z.Naudotojai)
                .HasForeignKey(nz => nz.Zinuteid)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Testas>()
                .Property(t => t.Tipas)
                .HasColumnType("public.testotipas");

            modelBuilder.Entity<TestasIrasas>()
                .HasKey(t => t.Id);
            
            modelBuilder.Entity<TestasIrasas>()
                .HasIndex(t => new { t.Testasid, t.Irasasid })
                .IsUnique();

            modelBuilder.Entity<TestasIrasasPrivalomasZingsnisTemplate>()
                .HasKey(x => new { x.TestasIrasasId, x.ZingsnisTemplateId });

            modelBuilder.Entity<TestasIrasasPrivalomasZingsnisTemplate>()
                .HasOne(x => x.TestasIrasas)
                .WithMany()
                .HasForeignKey(x => x.TestasIrasasId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<TestasIrasasPrivalomasZingsnisTemplate>()
                .HasOne(x => x.ZingsnisTemplate)
                .WithMany()
                .HasForeignKey(x => x.ZingsnisTemplateId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<PrisegtasFailas>()
                .HasOne(p => p.Zingsnis)
                .WithMany()
                .HasForeignKey(p => p.ZingsnisId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<PrisegtasFailas>()
                .HasOne(p => p.ZingsnisTemplate)
                .WithMany()
                .HasForeignKey(p => p.ZingsnisTemplateId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Zingsnis>()
                .HasOne(z => z.TestasIrasas)
                .WithMany()
                .HasForeignKey(z => z.TestasIrasasId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<ZingsnisTemplate>()
                .HasOne(z => z.Testas)
                .WithMany()
                .HasForeignKey(z => z.TestasId)
                .OnDelete(DeleteBehavior.Cascade);
            
            modelBuilder.Entity<Zingsnis>()
                .HasOne(z => z.ZingsnisTemplate)
                .WithMany()
                .HasForeignKey(z => z.ZingsnisTemplateId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Testas>(entity =>
            {
                entity.ToTable("testas");
                
                entity.Property(e => e.Tipas)
                    .HasColumnType("public.testotipas") 
                    .HasConversion<string>();
            });

            modelBuilder.Entity<Irasas>()
                .HasOne(i => i.Lokacija)
                .WithMany()
                .HasForeignKey(i => i.LokacijaId)
                .OnDelete(DeleteBehavior.Restrict);
        }
    }
}
