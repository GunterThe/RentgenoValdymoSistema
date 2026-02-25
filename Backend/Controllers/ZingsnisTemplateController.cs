using System.Collections.Generic;
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
            _db.ZingsnisTemplate.Add(template);
            await _db.SaveChangesAsync();
            return CreatedAtAction(nameof(Get), new { id = template.Id }, template);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, ZingsnisTemplate template)
        {
            if (id != template.Id) return BadRequest();
            _db.Entry(template).State = EntityState.Modified;
            try
            {
                await _db.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
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
