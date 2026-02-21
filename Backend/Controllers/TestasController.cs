using System.Collections.Generic;
using System.Threading.Tasks;
using Backend.Data;
using Backend.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Backend.Controllers
{
    [ApiController]
    [Authorize]
    [Route("api/[controller]")]
    public class TestasController : ControllerBase
    {
        private readonly AppDbContext _db;
        public TestasController(AppDbContext db) => _db = db;

        [HttpGet]
        public async Task<ActionResult<IEnumerable<Testas>>> GetAll() => await _db.Testai.ToListAsync();

        [HttpGet("{id}")]
        public async Task<ActionResult<Testas>> Get(int id)
        {
            var item = await _db.Testai.FindAsync(id);
            if (item == null) return NotFound();
            return item;
        }

        [HttpPost]
        public async Task<ActionResult<Testas>> Create(Testas testas)
        {
            _db.Testai.Add(testas);
            await _db.SaveChangesAsync();
            return CreatedAtAction(nameof(Get), new { id = testas.Id }, testas);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, Testas testas)
        {
            if (id != testas.Id) return BadRequest();
            _db.Entry(testas).State = EntityState.Modified;
            await _db.SaveChangesAsync();
            return NoContent();
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var item = await _db.Testai.FindAsync(id);
            if (item == null) return NotFound();
            _db.Testai.Remove(item);
            await _db.SaveChangesAsync();
            return NoContent();
        }
    }
}
