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
    public class RowValueController : ControllerBase
    {
        private readonly AppDbContext _db;
        public RowValueController(AppDbContext db) => _db = db;

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
        public async Task<ActionResult<IEnumerable<RowValue>>> GetAll() =>
            await _db.RowValues.ToListAsync();

        [HttpGet("{id}")]
        public async Task<ActionResult<RowValue>> Get(int id)
        {
            var item = await _db.RowValues.FindAsync(id);
            if (item == null) return NotFound();
            return item;
        }

        [HttpPost]
        [Authorize(Policy = "AdminOnly")]
        public async Task<ActionResult<RowValue>> Create(RowValue rowValue)
        {
            // default to 'empty' when not provided
            if (string.IsNullOrWhiteSpace(rowValue.Value)) rowValue.Value = "empty";
            string temp = rowValue.Value;
            if (temp != "compliant" && temp != "non-compliant" && temp != "not-specified" && temp != "empty")
            {
                return BadRequest("Value must be 'compliant', 'non-compliant', 'not-specified', or 'empty'.");
            }
            rowValue.CompletedAt = rowValue.CompletedAt.HasValue ? EnsureUtc(rowValue.CompletedAt.Value) : (DateTime?)null;
            _db.RowValues.Add(rowValue);
            await _db.SaveChangesAsync();
            return CreatedAtAction(nameof(Get), new { id = rowValue.Id }, rowValue);
        }

        [HttpPut("{id}")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> Update(int id, RowValue rowValue)
        {
            if (id != rowValue.Id) return BadRequest();

            var existing = await _db.RowValues.FirstOrDefaultAsync(r => r.Id == id);
            if (existing == null) return NotFound();
            // default to 'empty' when not provided
            if (string.IsNullOrWhiteSpace(rowValue.Value)) rowValue.Value = "empty";

            string temp = rowValue.Value.ToLower().Trim();
            if (temp != "compliant" && temp != "non-compliant" && temp != "not-specified" && temp != "empty")
            {
                return BadRequest("Value must be 'compliant', 'non-compliant', 'not-specified', or 'empty'.");
            }

            bool isAdmin = User.HasClaim("admin", bool.TrueString);
            if (!isAdmin)
                return Forbid();

            existing.Value = rowValue.Value;
            existing.CompletedAt = rowValue.CompletedAt.HasValue ? EnsureUtc(rowValue.CompletedAt.Value) : (DateTime?)null;
            existing.CompletedByUserId = rowValue.CompletedByUserId;
            existing.RowId = rowValue.RowId;
            existing.RowIrasasId = rowValue.RowIrasasId;

            try
            {
                await _db.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!await _db.RowValues.AnyAsync(e => e.Id == id)) return NotFound();
                throw;
            }

            return NoContent();
        }

        [HttpDelete("{id}")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> Delete(int id)
        {
            var item = await _db.RowValues.FindAsync(id);
            if (item == null) return NotFound();
            _db.RowValues.Remove(item);
            await _db.SaveChangesAsync();
            return NoContent();
        }
    }
}
