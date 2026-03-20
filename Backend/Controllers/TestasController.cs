using System.Collections.Generic;
using System.Reflection;
using System.Threading.Tasks;
using Backend.Data;
using Backend.Models;
using Microsoft.AspNetCore.Authorization;
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
            // Avoid EF trying to send enum as text; cast explicitly to Postgres enum type.
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

            // Return the created entity (freshly loaded from DB).
            var created = await _db.Testai.AsNoTracking().FirstAsync(t => t.Id == newId);
            return CreatedAtAction(nameof(Get), new { id = created.Id }, created);
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
