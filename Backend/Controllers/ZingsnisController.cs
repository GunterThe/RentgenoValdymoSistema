using System.Collections.Generic;
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
    public class ZingsnisController : ControllerBase
    {
        private readonly AppDbContext _db;
        public ZingsnisController(AppDbContext db) => _db = db;

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
        public async Task<ActionResult<IEnumerable<Zingsnis>>> GetAll() =>
            await _db.Zingsniai.ToListAsync();

        [HttpGet("{id}")]
        public async Task<ActionResult<Zingsnis>> Get(int id)
        {
            var item = await _db.Zingsniai.FindAsync(id);
            if (item == null) return NotFound();
            return item;
        }
        [HttpGet("getByEverything/{testasIrasasId}/{zingsnisTemplateId}")]
        public async Task<ActionResult<Zingsnis>> GetByEverything(int testasIrasasId, int zingsnisTemplateId)
        {
            var item = await _db.Zingsniai.FirstOrDefaultAsync(z => z.TestasIrasasId == testasIrasasId && z.ZingsnisTemplateId == zingsnisTemplateId);
            if (item == null) return NotFound();
            return item;
        }

        [HttpPost]
        [Authorize(Policy = "AdminOnly")]
        public async Task<ActionResult<Zingsnis>> Create(Zingsnis zingsnis)
        {
            if (zingsnis.CompletedAt == null) zingsnis.Pabaigtas = false; else zingsnis.Pabaigtas = true;
            _db.Zingsniai.Add(zingsnis);
            await _db.SaveChangesAsync();
            return CreatedAtAction(nameof(Get), new { id = zingsnis.Id }, zingsnis);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, Zingsnis zingsnis)
        {
            Zingsnis? temp = await _db.Zingsniai.AsNoTracking().FirstOrDefaultAsync(z => z.Id == id);
            if (temp == null) return NotFound();
            bool isAdmin = User.HasClaim("admin", bool.TrueString);
            if (id != zingsnis.Id) return BadRequest();
            if (zingsnis.CompletedAt == null)
            {
                if (temp == null) return NotFound();

                if (temp.CompletedAt != null && !isAdmin)
                {
                    return Forbid();
                }
            }
            else
            {
                zingsnis.Pabaigtas = true;
            }

            _db.Entry(zingsnis).State = EntityState.Modified;
            await _db.SaveChangesAsync();

            var template = await _db.ZingsnisTemplate.AsNoTracking().FirstOrDefaultAsync(t => t.Id == temp.ZingsnisTemplateId);
            var testasIrasas = await _db.TestasIrasai.AsNoTracking().FirstOrDefaultAsync(t => t.Id == temp.TestasIrasasId);

            bool areAllZingsniaiCompleted  = false;
            bool isLastTestasInIrasas = false;

            if (template != null && testasIrasas != null)
            {
                var zingsniai = await _db.Zingsniai
                    .AsNoTracking()
                    .Where(z => z.TestasIrasasId == temp.TestasIrasasId)
                    .ToListAsync();
                areAllZingsniaiCompleted = zingsniai.All(z => z.CompletedAt != null);

                var maxTestEile = await _db.TestasIrasai.Where(t => t.Irasasid == testasIrasas.Irasasid).MaxAsync(t => t.Eile);
                isLastTestasInIrasas = testasIrasas.Eile == maxTestEile;
            }
            if (testasIrasas != null && areAllZingsniaiCompleted && isLastTestasInIrasas)
            {
                Irasas? irasas = await _db.Irasai.AsNoTracking().FirstOrDefaultAsync(i => i.Id == testasIrasas.Irasasid);
                if (irasas != null)
                {
                    irasas.Pabaiga = DateTime.UtcNow;
                    _db.Irasai.Attach(irasas);
                    _db.Entry(irasas).Property(i => i.Pabaiga).IsModified = true;
                }
            }
            else if (testasIrasas != null && !areAllZingsniaiCompleted)
            {
                Irasas? irasas = await _db.Irasai.AsNoTracking().FirstOrDefaultAsync(i => i.Id == testasIrasas.Irasasid);
                if (irasas != null)
                {
                    irasas.Pabaiga = null;
                    _db.Irasai.Attach(irasas);
                    _db.Entry(irasas).Property(i => i.Pabaiga).IsModified = true;
                }
            }

            await _db.SaveChangesAsync();
            return NoContent();
        }

        [HttpDelete("{id}")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> Delete(int id)
        {
            var item = await _db.Zingsniai.FindAsync(id);
            if (item == null) return NotFound();
            _db.Zingsniai.Remove(item);
            await _db.SaveChangesAsync();
            return NoContent();
        }
    }
}
