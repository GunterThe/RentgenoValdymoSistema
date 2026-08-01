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
    public class RowIrasasController : ControllerBase
    {
        private readonly AppDbContext _db;
        public RowIrasasController(AppDbContext db) => _db = db;

        [HttpGet]
        public async Task<ActionResult<IEnumerable<RowIrasas>>> GetAll() => await _db.RowIrasai.ToListAsync();

        [HttpGet("{id:int}")]
        public async Task<ActionResult<RowIrasas>> GetById(int id)
        {
            var item = await _db.RowIrasai.FindAsync(id);
            if (item == null) return NotFound();
            return item;
        }

        // Backwards compatible route (composite unique index)
        [HttpGet("{rowid:int}/{irasasid:int}")]
        public async Task<ActionResult<RowIrasas>> GetByPair(int rowid, int irasasid)
        {
            var item = await _db.RowIrasai
                .FirstOrDefaultAsync(x => x.RowId == rowid && x.IrasasId == irasasid);
            if (item == null) return NotFound();
            return item;
        }

        [HttpPost]
        [Authorize(Policy = "AdminOnly")]
        public async Task<ActionResult<RowIrasas>> Create(RowIrasas model)
        {
            _db.RowIrasai.Add(model);
            var last = await _db.RowIrasai.Where(z => z.IrasasId == model.IrasasId).OrderByDescending(z => z.Order).FirstOrDefaultAsync();
            model.Order = last == null ? 1 : last.Order + 1;
            await _db.SaveChangesAsync();
            return CreatedAtAction(
                nameof(GetById),
                new { id = model.Id },
                model
            );
        }

        [HttpPut("{id:int}")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> Update(int id, RowIrasas model)
        {
            if (id != model.Id) return BadRequest();
            _db.Entry(model).State = EntityState.Modified;
            await _db.SaveChangesAsync();
            return NoContent();
        }

        // Backwards compatible route
        [HttpPut("{rowid:int}/{irasasid:int}")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> UpdateByPair(int rowid, int irasasid, RowIrasas model)
        {
            if (rowid != model.RowId || irasasid != model.IrasasId) return BadRequest();

            var existing = await _db.RowIrasai
                .FirstOrDefaultAsync(x => x.RowId == rowid && x.IrasasId == irasasid);
            if (existing == null) return NotFound();

            existing.RowId = model.RowId;
            existing.IrasasId = model.IrasasId;
            await _db.SaveChangesAsync();
            return NoContent();
        }

        [HttpDelete("{id:int}")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> Delete(int id)
        {
            var item = await _db.RowIrasai.FindAsync(id);
            if (item == null) return NotFound();
            _db.ColumnValues.RemoveRange(_db.ColumnValues.Where(z => z.RowIrasasId == item.Id));
            _db.RowIrasai.Remove(item);
            await _db.SaveChangesAsync();
            return NoContent();
        }

        // Backwards compatible route
        [HttpDelete("{rowid:int}/{irasasid:int}")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> DeleteByPair(int rowid, int irasasid)
        {
            var item = await _db.RowIrasai
                .FirstOrDefaultAsync(x => x.RowId == rowid && x.IrasasId == irasasid);
            if (item == null) return NotFound();
            _db.RowIrasai.Remove(item);
            await _db.SaveChangesAsync();
            return NoContent();
        }
    }
}