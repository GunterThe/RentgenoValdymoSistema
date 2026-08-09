using System.Collections.Generic;
using System.Threading.Tasks;
using Backend.Data;
using Backend.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authorization;
using System.Linq;

namespace Backend.Controllers
{
    [ApiController]
    [Authorize]
    [Route("api/[controller]")]
    public class FATReportIrasasController : ControllerBase
    {
        private readonly AppDbContext _db;
        public FATReportIrasasController(AppDbContext db) => _db = db;

        [HttpGet]
        public async Task<ActionResult<IEnumerable<FATReportIrasas>>> GetAll() => await _db.FATReportIrasai.ToListAsync();

        [HttpGet("{id:int}")]
        public async Task<ActionResult<FATReportIrasas>> GetById(int id)
        {
            var item = await _db.FATReportIrasai.FindAsync(id);
            if (item == null) return NotFound();
            return item;
        }

        // Backwards compatible route (composite unique index)
        [HttpGet("{fatreportid:int}/{irasasid:int}")]
        public async Task<ActionResult<FATReportIrasas>> GetByPair(int fatreportid, int irasasid)
        {
            var item = await _db.FATReportIrasai
                .FirstOrDefaultAsync(x => x.FATReportId == fatreportid && x.IrasasId == irasasid);
            if (item == null) return NotFound();
            return item;
        }

        [HttpPost]
        [Authorize(Policy = "AdminOnly")]
        public async Task<ActionResult<FATReportIrasas>> Create(FATReportIrasas model)
        {
            model.Order = await _db.FATReportIrasai
                .Where(z => z.FATReportId == model.FATReportId)
                .MaxAsync(z => (int?)z.Order) ?? 0 + 1;
            _db.FATReportIrasai.Add(model);
            await _db.SaveChangesAsync();
            return CreatedAtAction(
                nameof(GetById),
                new { id = model.Id },
                model
            );
        }

        [HttpPut("{id:int}")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> Update(int id, FATReportIrasas model)
        {
            if (id != model.Id) return BadRequest();
            _db.Entry(model).State = EntityState.Modified;
            await _db.SaveChangesAsync();
            return NoContent();
        }

        // Backwards compatible route
        [HttpPut("{testasid:int}/{irasasid:int}")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> UpdateByPair(int fatreportid, int irasasid, FATReportIrasas model)
        {
            if (fatreportid != model.FATReportId || irasasid != model.IrasasId) return BadRequest();

            var existing = await _db.FATReportIrasai
                .FirstOrDefaultAsync(x => x.FATReportId == fatreportid && x.IrasasId == irasasid);
            if (existing == null) return NotFound();

            existing.FATReportId = model.FATReportId;
            existing.IrasasId = model.IrasasId;
            await _db.SaveChangesAsync();
            return NoContent();
        }

        [HttpDelete("{id:int}")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> Delete(int id)
        {
            var item = await _db.FATReportIrasai.FindAsync(id);
            if (item == null) return NotFound();
            _db.ReportValues.RemoveRange(_db.ReportValues.Where(z => z.FATReportIrasasId == id));
            _db.FATReportIrasai.Remove(item);
            await _db.SaveChangesAsync();
            return NoContent();
        }

        // Backwards compatible route
        [HttpDelete("{fatreportid:int}/{irasasid:int}")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> DeleteByPair(int fatreportid, int irasasid)
        {
            var item = await _db.FATReportIrasai
                .FirstOrDefaultAsync(x => x.FATReportId == fatreportid && x.IrasasId == irasasid);
            if (item == null) return NotFound();
            _db.FATReportIrasai.Remove(item);
            await _db.SaveChangesAsync();
            return NoContent();
        }
    }
}