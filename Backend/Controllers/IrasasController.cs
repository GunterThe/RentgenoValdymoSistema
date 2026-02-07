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
    public class IrasasController : ControllerBase
    {
        private readonly AppDbContext _db;
        public IrasasController(AppDbContext db) => _db = db;

        [HttpGet]
        public async Task<ActionResult<IEnumerable<Irasas>>> GetAll() => await _db.Irasai.ToListAsync();

        [HttpGet("{id}")]
        public async Task<ActionResult<Irasas>> Get(int id)
        {
            var item = await _db.Irasai.FindAsync(id);
            if (item == null) return NotFound();
            return item;
        }

        [HttpPost]
        public async Task<ActionResult<Irasas>> Create(Irasas irasas)
        {
            _db.Irasai.Add(irasas);
            await _db.SaveChangesAsync();
            return CreatedAtAction(nameof(Get), new { id = irasas.Id }, irasas);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, Irasas irasas)
        {
            if (id != irasas.Id) return BadRequest();
            _db.Entry(irasas).State = EntityState.Modified;
            await _db.SaveChangesAsync();
            return NoContent();
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var item = await _db.Irasai.FindAsync(id);
            if (item == null) return NotFound();
            _db.Irasai.Remove(item);
            await _db.SaveChangesAsync();
            return NoContent();
        }
    }
}
