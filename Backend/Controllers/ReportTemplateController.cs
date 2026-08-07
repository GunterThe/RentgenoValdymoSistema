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
    public class ReportTemplateController : ControllerBase
    {
        private readonly AppDbContext _db;
        public ReportTemplateController(AppDbContext db) => _db = db;

        [HttpGet]
        public async Task<ActionResult<IEnumerable<ReportTemplate>>> GetAll() =>
            await _db.ReportTemplates.ToListAsync();

        [HttpGet("{id}")]
        public async Task<ActionResult<ReportTemplate>> Get(int id)
        {
            var item = await _db.ReportTemplates.FindAsync(id);
            if (item == null) return NotFound();
            return item;
        }

        [HttpPost]
        [Authorize(Policy = "AdminOnly")]
        public async Task<ActionResult<ReportTemplate>> Create(ReportTemplate template)
        {
            int order = 1;
            var last = await _db.ReportTemplates.Where(z => z.FATReportId == template.FATReportId).OrderByDescending(z => z.Order).FirstOrDefaultAsync();
            if (last != null) order = last.Order + 1;
            template.Order = order;
            _db.ReportTemplates.Add(template);
            await _db.SaveChangesAsync();
            return CreatedAtAction(nameof(Get), new { id = template.Id }, template);
        }

        [HttpPut("{id}")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> Update(int id, ReportTemplate template)
        {
            if (id != template.Id) return BadRequest();

            var existing = await _db.ReportTemplates.FirstOrDefaultAsync(z => z.Id == id);
            if (existing == null) return NotFound();

            var oldATReportId = existing.FATReportId;
            var oldOrder = existing.Order;
            var newFATReportId = template.FATReportId;
            var requestedOrder = template.Order;

            if (requestedOrder < 1) requestedOrder = 1;

            await using var tx = await _db.Database.BeginTransactionAsync();
            try
            {

                existing.Text = template.Text;

                var siblings = await _db.ReportTemplates
                    .Where(z => z.FATReportId == oldATReportId && z.Id != existing.Id)
                    .ToListAsync();

                var maxEile = siblings.Count + 1;
                var newOrder = requestedOrder > maxEile ? maxEile : requestedOrder;

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
                if (!await _db.ReportTemplates.AnyAsync(e => e.Id == id)) return NotFound();
                throw;
            }

            return NoContent();
        }

        [HttpDelete("{id}")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> Delete(int id)
        {
            var item = await _db.ReportTemplates.FindAsync(id);
            if (item == null) return NotFound();
            int order = item.Order;
            var siblings = await _db.ReportTemplates
                .Where(z => z.FATReportId == item.FATReportId && z.Id != item.Id)
                .ToListAsync();
            foreach (var s in siblings.Where(s => s.Order > order))
                s.Order -= 1;

            _db.ReportTemplates.Remove(item);
            await _db.SaveChangesAsync();
            return NoContent();
        }
    }
}