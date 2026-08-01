using System.Collections.Generic;
using System;
using System.IO;
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
    public class ColumnValueController : ControllerBase
    {
        private readonly AppDbContext _db;
        public ColumnValueController(AppDbContext db) => _db = db;

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
        public async Task<ActionResult<IEnumerable<ColumnValue>>> GetAll() =>
            await _db.ColumnValues.ToListAsync();

        [HttpGet("{id}")]
        public async Task<ActionResult<ColumnValue>> Get(int id)
        {
            var item = await _db.ColumnValues.FindAsync(id);
            if (item == null) return NotFound();
            return item;
        }
        [HttpGet("getByEverything/{rowIrasasId}/{columnTemplateId}")]
        public async Task<ActionResult<ColumnValue>> GetByEverything(int rowIrasasId, int columnTemplateId)
        {
            var item = await _db.ColumnValues.FirstOrDefaultAsync(z => z.RowIrasasId == rowIrasasId && z.ColumnTemplateId == columnTemplateId);
            if (item == null) return NotFound();
            return item;
        }

        [HttpPost]
        public async Task<ActionResult<ColumnValue>> Create(ColumnValue columnValue)
        {
            if (columnValue.CompletedAt == null) columnValue.Pabaigtas = false; else columnValue.Pabaigtas = true;
            ColumnTemplate? template = await _db.ColumnTemplates.AsNoTracking().FirstOrDefaultAsync(z => z.Id == columnValue.ColumnTemplateId);
            if (template == null) return BadRequest("Column template not found.");

            if (template.IsArray)
            {
                if (columnValue.ArrayValue == null || columnValue.ArrayValue.Length == 0)
                {
                    return BadRequest("Array value is required for this column template.");
                }
            }
            else
            {
                if (columnValue.SingleValue == null)
                {
                    return BadRequest("Single value is required for this column template.");
                }
            }

            _db.ColumnValues.Add(columnValue);
            await _db.SaveChangesAsync();
            return CreatedAtAction(nameof(Get), new { id = columnValue.Id }, columnValue);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, ColumnValue columnValue)
        {
            ColumnValue? temp = await _db.ColumnValues.AsNoTracking().FirstOrDefaultAsync(z => z.Id == id);
            if (temp == null) return NotFound();
            bool isAdmin = User.HasClaim("admin", bool.TrueString);
            if (id != columnValue.Id) return BadRequest();
            if (columnValue.CompletedAt == null)
            {
                if (temp == null) return NotFound();

                if (temp.CompletedAt != null && !isAdmin)
                {
                    return Forbid();
                }
            }
            else
            {
                columnValue.Pabaigtas = true;
            }

            if (columnValue.CompletedAt != null)
            {
                columnValue.CompletedAt = EnsureUtc(columnValue.CompletedAt.Value);
            }

            _db.Entry(columnValue).State = EntityState.Modified;
            await _db.SaveChangesAsync();
            return NoContent();
        }

        [HttpDelete("{id}")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> Delete(int id)
        {
            var item = await _db.ColumnValues.FindAsync(id);
            if (item == null) return NotFound();

            _db.ColumnValues.Remove(item);
            await _db.SaveChangesAsync();

            return NoContent();
        }
    }
}
