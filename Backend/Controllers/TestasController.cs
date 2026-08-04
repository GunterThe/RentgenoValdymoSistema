using System.Collections.Generic;
using System;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Threading.Tasks;
using Backend.Data;
using Backend.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore.Storage;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Npgsql;
using NpgsqlTypes;

namespace Backend.Controllers
{
    [ApiController]
    [Authorize]
    [Route("api/[controller]")]
    public class TestasController : ControllerBase
    {
        private readonly AppDbContext _db;
        public TestasController(AppDbContext db) => _db = db;

        [HttpGet]
        public async Task<ActionResult<IEnumerable<Testas>>> GetAll() => await _db.Testai.ToListAsync();

        [HttpGet("{id}")]
        public async Task<ActionResult<Testas>> Get(int id)
        {
            var item = await _db.Testai.FindAsync(id);
            if (item == null) return NotFound();
            return item;
        }

        [HttpPost]
        [Authorize(Policy = "AdminOnly")]
        public async Task<ActionResult<Testas>> Create(Testas testas)
        {
            int newId;
            await using (var cmd = _db.Database.GetDbConnection().CreateCommand())
            {
                if (cmd.Connection!.State != System.Data.ConnectionState.Open)
                    await cmd.Connection.OpenAsync();

                if (testas.Tipas == null)
                {
                    cmd.CommandText = @"INSERT INTO public.testas (testotekstas, tipas)
                    VALUES (@text, NULL)
                    RETURNING id;";
                }
                else
                {
                    cmd.CommandText = @"INSERT INTO public.testas (testotekstas, tipas)
                    VALUES (@text, (@tipas)::public.testotipas)
                    RETURNING id;";
                    var pgEnumValue = GetPgEnumName(testas.Tipas.Value);
                    cmd.Parameters.Add(new NpgsqlParameter("tipas", pgEnumValue));
                }

                cmd.Parameters.Add(new NpgsqlParameter("text", testas.Testotekstas));
                var scalar = await cmd.ExecuteScalarAsync();
                newId = scalar == null ? 0 : System.Convert.ToInt32(scalar);
            }

            var created = await _db.Testai.AsNoTracking().FirstAsync(t => t.Id == newId);
            return CreatedAtAction(nameof(Get), new { id = created.Id }, created);
        }

        public class CopyTestasRequest
        {
            public string? NewTestotekstas { get; set; }
        }

        [HttpPost("copy/{id}")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<ActionResult<Testas>> Copy(int id, [FromBody] CopyTestasRequest? req)
        {
            var original = await _db.Testai.AsNoTracking().FirstOrDefaultAsync(t => t.Id == id);
            if (original == null) return NotFound();
            var templates = await _db.ZingsnisTemplate
                .Where(z => z.TestasId == id)
                .OrderBy(z => z.Eile)
                .AsNoTracking()
                .ToListAsync();

            var newTestotekstas = !string.IsNullOrWhiteSpace(req?.NewTestotekstas)
                ? req!.NewTestotekstas!.Trim()
                : original.Testotekstas;

            // Use EF Core transaction and regular EF inserts to avoid mixing raw commands and completed transactions
            await using var tx = await _db.Database.BeginTransactionAsync();
            try
            {
                // Insert `testas` using raw SQL with enum cast to avoid EF sending text into enum column
                var conn = _db.Database.GetDbConnection();
                if (conn.State != System.Data.ConnectionState.Open) await conn.OpenAsync();

                var underlyingTr = tx.GetDbTransaction();

                int newId;
                await using (var cmd = conn.CreateCommand())
                {
                    cmd.Transaction = underlyingTr;

                    if (original.Tipas == null)
                    {
                        cmd.CommandText = @"INSERT INTO public.testas (testotekstas, tipas)
                    VALUES (@text, NULL)
                    RETURNING id;";
                    }
                    else
                    {
                        cmd.CommandText = @"INSERT INTO public.testas (testotekstas, tipas)
                    VALUES (@text, (@tipas)::public.testotipas)
                    RETURNING id;";
                        var pgEnumValue = GetPgEnumName(original.Tipas.Value);
                        cmd.Parameters.Add(new NpgsqlParameter("tipas", pgEnumValue));
                    }

                    cmd.Parameters.Add(new NpgsqlParameter("text", newTestotekstas));
                    var scalar = await cmd.ExecuteScalarAsync();
                    newId = scalar == null ? 0 : System.Convert.ToInt32(scalar);
                }

                // copy templates and attached DB rows
                foreach (var t in templates)
                {
                    var newTemplate = new ZingsnisTemplate
                    {
                        Pavadinimas = t.Pavadinimas,
                        Aprasymas = t.Aprasymas,
                        TestasId = newId,
                        Eile = t.Eile,
                        KomentarasPrivalomas = t.KomentarasPrivalomas,
                        NuotraukaPrivaloma = t.NuotraukaPrivaloma
                    };
                    _db.ZingsnisTemplate.Add(newTemplate);
                    await _db.SaveChangesAsync();
                    var newTemplateId = newTemplate.Id;

                    var files = await _db.PrisegtiFailai
                        .Where(p => p.ZingsnisTemplateId == t.Id)
                        .AsNoTracking()
                        .ToListAsync();

                    foreach (var f in files)
                    {
                        var newModel = new PrisegtasFailas
                        {
                            Id = Guid.NewGuid(),
                            ZingsnisId = null,
                            ZingsnisTemplateId = newTemplateId,
                            FailoPav = f.FailoPav,
                            Dydis = f.Dydis,
                            Nuoroda = f.Nuoroda,
                            SukurimoLaikas = System.DateTime.UtcNow
                        };
                        _db.PrisegtiFailai.Add(newModel);
                        await _db.SaveChangesAsync();
                    }
                }

                await tx.CommitAsync();
                var created = await _db.Testai.AsNoTracking().FirstAsync(t => t.Id == newId);
                return CreatedAtAction(nameof(Get), new { id = created.Id }, created);
            }
            catch
            {
                await tx.RollbackAsync();
                throw;
            }
        }

        [HttpPut("{id}")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> Update(int id, Testas testas)
        {
            if (id != testas.Id) return BadRequest();
            var exists = await _db.Testai.AsNoTracking().AnyAsync(t => t.Id == id);
            if (!exists) return NotFound();

            if (testas.Tipas == null)
            {
                await _db.Database.ExecuteSqlInterpolatedAsync($@"
                UPDATE public.testas
                SET testotekstas = {testas.Testotekstas},
                    tipas = NULL
                WHERE id = {id};");
            }
            else
            {
                var pgEnumValue = GetPgEnumName(testas.Tipas.Value);
                await _db.Database.ExecuteSqlInterpolatedAsync($@"
                UPDATE public.testas
                SET testotekstas = {testas.Testotekstas},
                    tipas = {pgEnumValue}::public.testotipas
                WHERE id = {id};");
            }

            return NoContent();
        }

        private static string GetPgEnumName<TEnum>(TEnum value)
            where TEnum : struct, System.Enum
        {
            var member = typeof(TEnum).GetMember(value.ToString())[0];
            var attr = member.GetCustomAttribute<PgNameAttribute>();
            return attr?.PgName ?? value.ToString();
        }

        [HttpDelete("{id}")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> Delete(int id)
        {
            var item = await _db.Testai.FindAsync(id);
            if (item == null) return NotFound();
            _db.Testai.Remove(item);
            await _db.SaveChangesAsync();
            return NoContent();
        }
    }
}
