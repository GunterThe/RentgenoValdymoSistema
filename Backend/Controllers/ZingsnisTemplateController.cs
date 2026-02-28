using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Backend.Data;
using Backend.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ZingsnisTemplateController : ControllerBase
    {
        private readonly AppDbContext _db;
        public ZingsnisTemplateController(AppDbContext db) => _db = db;

        [HttpGet]
        public async Task<ActionResult<IEnumerable<ZingsnisTemplate>>> GetAll() =>
            await _db.ZingsnisTemplate.ToListAsync();

        [HttpGet("{id}")]
        public async Task<ActionResult<ZingsnisTemplate>> Get(int id)
        {
            var item = await _db.ZingsnisTemplate.FindAsync(id);
            if (item == null) return NotFound();
            return item;
        }

        [HttpPost]
        public async Task<ActionResult<ZingsnisTemplate>> Create(ZingsnisTemplate template)
        {
            int eile = 1;
            var last = await _db.ZingsnisTemplate.Where(z => z.TestasId == template.TestasId).OrderByDescending(z => z.Eile).FirstOrDefaultAsync();
            if (last != null) eile = last.Eile + 1;
            template.Eile = eile;
            _db.ZingsnisTemplate.Add(template);
            await _db.SaveChangesAsync();
            return CreatedAtAction(nameof(Get), new { id = template.Id }, template);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, ZingsnisTemplate template)
        {
            if (id != template.Id) return BadRequest();

            var existing = await _db.ZingsnisTemplate.FirstOrDefaultAsync(z => z.Id == id);
            if (existing == null) return NotFound();

            var oldTestasId = existing.TestasId;
            var oldEile = existing.Eile;
            var newTestasId = template.TestasId;
            var requestedEile = template.Eile;

            if (requestedEile < 1) requestedEile = 1;

            await using var tx = await _db.Database.BeginTransactionAsync();
            try
            {

                existing.Pavadinimas = template.Pavadinimas;
                existing.Aprasymas = template.Aprasymas;

                var siblings = await _db.ZingsnisTemplate
                    .Where(z => z.TestasId == oldTestasId && z.Id != existing.Id)
                    .ToListAsync();

                var maxEile = siblings.Count + 1;
                var newEile = requestedEile > maxEile ? maxEile : requestedEile;

                if (newEile < oldEile)
                {
                    foreach (var s in siblings.Where(s => s.Eile >= newEile && s.Eile < oldEile))
                        s.Eile += 1;
                }
                else if (newEile > oldEile)
                {
                    foreach (var s in siblings.Where(s => s.Eile <= newEile && s.Eile > oldEile))
                        s.Eile -= 1;
                }

                existing.Eile = newEile;

                await _db.SaveChangesAsync();
                await tx.CommitAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                await tx.RollbackAsync();
                if (!await _db.ZingsnisTemplate.AnyAsync(e => e.Id == id)) return NotFound();
                throw;
            }

            return NoContent();
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var item = await _db.ZingsnisTemplate.FindAsync(id);
            if (item == null) return NotFound();
            _db.ZingsnisTemplate.Remove(item);
            await _db.SaveChangesAsync();
            return NoContent();
        }
    }
}
