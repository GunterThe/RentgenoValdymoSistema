using System.Collections.Generic;
using System;
using System.Threading.Tasks;
using Backend.Data;
using Backend.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authorization;

namespace Backend.Controllers
{
    [ApiController]
    [Authorize]
    [Route("api/[controller]")]
    public class IrasasController : ControllerBase
    {
        private readonly AppDbContext _db;
        public IrasasController(AppDbContext db) => _db = db;

		public class CreateIrasasRequest
		{
			public string IdDokumento { get; set; } = null!;
			public string Pavadinimas { get; set; } = null!;
			public int LokacijaId { get; set; }
			public int? SablonasId { get; set; }
		}

        private static DateTime EnsureUtc(DateTime dt)
        {
            return dt.Kind switch
            {
                DateTimeKind.Utc => dt,
                DateTimeKind.Local => dt.ToUniversalTime(),
                DateTimeKind.Unspecified => DateTime.SpecifyKind(dt, DateTimeKind.Local).ToUniversalTime(),
                _ => DateTime.SpecifyKind(dt, DateTimeKind.Utc)
            };
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<Irasas>>> GetAll() => await _db.Irasai.ToListAsync();

        [HttpGet("{id}")]
        public async Task<ActionResult<Irasas>> Get(int id)
        {
            var item = await _db.Irasai.FindAsync(id);
            if (item == null) return NotFound();
            return item;
        }

        [HttpPost]
        [Authorize(Policy = "AdminOnly")]
        public async Task<ActionResult<Irasas>> Create(CreateIrasasRequest request)
        {
            if (request == null) return BadRequest();
            if (string.IsNullOrWhiteSpace(request.IdDokumento))
                return BadRequest(new { message = "IdDokumento is required" });
            if (string.IsNullOrWhiteSpace(request.Pavadinimas))
                return BadRequest(new { message = "Pavadinimas is required" });
            if (request.LokacijaId <= 0)
                return BadRequest(new { message = "LokacijaId is required" });

            if (request.SablonasId != null)
            {
                var sablonasExists = await _db.Sablonai.AsNoTracking().AnyAsync(s => s.Id == request.SablonasId.Value);
                if (!sablonasExists)
                    return BadRequest(new { message = "Sablonas does not exist" });
            }

            var lokacijaExists = await _db.Lokacijos.AsNoTracking().AnyAsync(l => l.Id == request.LokacijaId);
            if (!lokacijaExists)
                return BadRequest(new { message = "Lokacija does not exist" });

            await using var tx = await _db.Database.BeginTransactionAsync();

            var irasas = new Irasas
            {
                IdDokumento = request.IdDokumento.Trim(),
                Pavadinimas = request.Pavadinimas.Trim(),
                LokacijaId = request.LokacijaId,
                Pradzia = EnsureUtc(DateTime.UtcNow),
                Pabaiga = null,
                Statusas = "Nepradėtas",
            };

            _db.Irasai.Add(irasas);
            await _db.SaveChangesAsync();

            if (request.SablonasId != null)
            {
                var testasIds = await _db.SablonasTestai
                    .AsNoTracking()
                    .Where(st => st.Sablonasid == request.SablonasId.Value)
                    .OrderBy(st => st.Testasid)
                    .Select(st => st.Testasid)
                    .Distinct()
                    .ToListAsync();

                if (testasIds.Count > 0)
                {
                    var links = new List<TestasIrasas>(capacity: testasIds.Count);
                    for (var idx = 0; idx < testasIds.Count; idx++)
                    {
                        links.Add(new TestasIrasas
                        {
                            Irasasid = irasas.Id,
                            Testasid = testasIds[idx],
                            Eile = idx + 1,
                        });
                    }
                    _db.TestasIrasai.AddRange(links);
                    await _db.SaveChangesAsync();
                }
            }

            await tx.CommitAsync();
            return CreatedAtAction(nameof(Get), new { id = irasas.Id }, irasas);
        }

        [HttpPut("{id}")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> Update(int id, Irasas irasas)
        {
            if (id != irasas.Id) return BadRequest();

            var existing = await _db.Irasai.FirstOrDefaultAsync(i => i.Id == id);
            if (existing == null) return NotFound();

            existing.IdDokumento = irasas.IdDokumento;
            existing.Pavadinimas = irasas.Pavadinimas;
            existing.Pradzia = EnsureUtc(irasas.Pradzia);
            existing.Pabaiga = irasas.Pabaiga == null ? null : EnsureUtc(irasas.Pabaiga.Value);

            await _db.SaveChangesAsync();
            return NoContent();
        }

        [HttpDelete("{id}")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> Delete(int id)
        {
            var item = await _db.Irasai.FindAsync(id);
            if (item == null) return NotFound();
            _db.Irasai.Remove(item);
            await _db.SaveChangesAsync();
            return NoContent();
        }
    }
}
