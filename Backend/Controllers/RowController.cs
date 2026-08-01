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
    public class RowController : ControllerBase
    {
        private readonly AppDbContext _db;
        public RowController(AppDbContext db) => _db = db;

        [HttpGet]
        public async Task<ActionResult<IEnumerable<Row>>> GetAll() => await _db.Rows.ToListAsync();

        [HttpGet("{id}")]
        public async Task<ActionResult<Row>> Get(int id)
        {
            var item = await _db.Rows.FindAsync(id);
            if (item == null) return NotFound();
            return item;
        }

        [HttpPost]
        [Authorize(Policy = "AdminOnly")]
        public async Task<ActionResult<Row>> Create(Row row)
        {
            _db.Rows.Add(row);
            await _db.SaveChangesAsync();
            return CreatedAtAction(nameof(Get), new { id = row.Id }, row);
        }

        [HttpPut("{id}")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> Update(int id, Row row)
        {
            if (id != row.Id) return BadRequest();
            var exists = await _db.Rows.AsNoTracking().AnyAsync(t => t.Id == id);
            if (!exists) return NotFound();

            _db.Entry(row).State = EntityState.Modified;
            await _db.SaveChangesAsync();

            return NoContent();
        }

        [HttpDelete("{id}")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> Delete(int id)
        {
            var item = await _db.Rows.FindAsync(id);
            if (item == null) return NotFound();
            _db.Rows.Remove(item);
            await _db.SaveChangesAsync();
            return NoContent();
        }
    }
}
