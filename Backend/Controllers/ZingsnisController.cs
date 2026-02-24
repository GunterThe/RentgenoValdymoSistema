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
    public class ZingsnisController : ControllerBase
    {
        private readonly AppDbContext _db;
        public ZingsnisController(AppDbContext db) => _db = db;

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

        [HttpPost]
        public async Task<ActionResult<Zingsnis>> Create(Zingsnis zingsnis)
        {
            _db.Zingsniai.Add(zingsnis);
            await _db.SaveChangesAsync();
            return CreatedAtAction(nameof(Get), new { id = zingsnis.Id }, zingsnis);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, Zingsnis zingsnis)
        {
            if (id != zingsnis.Id) return BadRequest();
            _db.Entry(zingsnis).State = EntityState.Modified;
            await _db.SaveChangesAsync();
            return NoContent();
        }

        [HttpDelete("{id}")]
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
