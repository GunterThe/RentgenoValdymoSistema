using System.Collections.Generic;
using System.Linq;
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
    public class ColumnTemplateController : ControllerBase
    {
        private readonly AppDbContext _db;
        public ColumnTemplateController(AppDbContext db) => _db = db;

        [HttpGet]
        public async Task<ActionResult<IEnumerable<ColumnTemplate>>> GetAll() =>
            await _db.ColumnTemplates.ToListAsync();

        [HttpGet("{id}")]
        public async Task<ActionResult<ColumnTemplate>> Get(int id)
        {
            var item = await _db.ColumnTemplates.FindAsync(id);
            if (item == null) return NotFound();
            return item;
        }

        [HttpPost]
        [Authorize(Policy = "AdminOnly")]
        public async Task<ActionResult<ColumnTemplate>> Create(ColumnTemplate template)
        {
            int eile = 1;
            var last = await _db.ColumnTemplates.Where(z => z.RowId == template.RowId).OrderByDescending(z => z.Order).FirstOrDefaultAsync();
            if (last != null) eile = last.Order + 1;
            template.Order = eile;
            _db.ColumnTemplates.Add(template);
            await _db.SaveChangesAsync();
            return CreatedAtAction(nameof(Get), new { id = template.Id }, template);
        }

        [HttpPut("{id}")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> Update(int id, ColumnTemplate template)
        {
            if (id != template.Id) return BadRequest();

            var existing = await _db.ColumnTemplates.FirstOrDefaultAsync(z => z.Id == id);
            if (existing == null) return NotFound();

            var oldRowId = existing.RowId;
            var oldOrder = existing.Order;
            var newRowId = template.RowId;
            var requestedOrder = template.Order;

            if (requestedOrder < 1) requestedOrder = 1;

            await using var tx = await _db.Database.BeginTransactionAsync();
            try
            {

                existing.Description = template.Description;
                existing.IsArray = template.IsArray;

                var siblings = await _db.ColumnTemplates
                    .Where(z => z.RowId == oldRowId && z.Id != existing.Id)
                    .ToListAsync();

                var maxOrder = siblings.Count + 1;
                var newOrder = requestedOrder > maxOrder ? maxOrder : requestedOrder;

                if (newOrder < oldOrder)
                {
                    foreach (var s in siblings.Where(s => s.Order >= newOrder && s.Order < oldOrder))
                        s.Order += 1;
                }
                else if (newOrder > oldOrder)
                {
                    foreach (var s in siblings.Where(s => s.Order <= newOrder && s.Order > oldOrder))
                        s.Order -= 1;
                }

                existing.Order = newOrder;

                await _db.SaveChangesAsync();
                await tx.CommitAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                await tx.RollbackAsync();
                if (!await _db.ColumnTemplates.AnyAsync(e => e.Id == id)) return NotFound();
                throw;
            }

            return NoContent();
        }

        [HttpDelete("{id}")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> Delete(int id)
        {
            var item = await _db.ColumnTemplates.FindAsync(id);
            if (item == null) return NotFound();
            int order = item.Order;
            var siblings = await _db.ColumnTemplates
                .Where(z => z.RowId == item.RowId && z.Id != item.Id)
                .ToListAsync();
            foreach (var s in siblings.Where(s => s.Order > order))
                s.Order -= 1;

            var tplFiles = await _db.PrisegtiFailai
                .Where(p => p.ZingsnisTemplateId == id)
                .ToListAsync();
            foreach (var f in tplFiles)
            {
                if (!string.IsNullOrWhiteSpace(f.Nuoroda))
                {
                    try
                    {
                        var path = System.IO.Path.Combine(System.IO.Directory.GetCurrentDirectory(), f.Nuoroda);
                        if (System.IO.File.Exists(path))
                            System.IO.File.Delete(path);
                    }
                    catch
                    {
                    }
                }
            }
            _db.PrisegtiFailai.RemoveRange(tplFiles);

            _db.Zingsniai.RemoveRange(_db.Zingsniai.Where(z => z.ZingsnisTemplateId == id));
            _db.ColumnTemplates.Remove(item);
            await _db.SaveChangesAsync();
            return NoContent();
        }
    }
}