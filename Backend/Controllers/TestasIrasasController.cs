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
    public class TestasIrasasController : ControllerBase
    {
        private readonly AppDbContext _db;
        public TestasIrasasController(AppDbContext db) => _db = db;

        [HttpGet]
        public async Task<ActionResult<IEnumerable<TestasIrasas>>> GetAll() => await _db.TestasIrasai.ToListAsync();

        [HttpGet("{testasid}/{irasasid}")]
        public async Task<ActionResult<TestasIrasas>> Get(int testasid, int irasid)
        {
            var item = await _db.TestasIrasai.FindAsync(testasid, irasid);
            if (item == null) return NotFound();
            return item;
        }

        [HttpPost]
        public async Task<ActionResult<TestasIrasas>> Create(TestasIrasas model)
        {
            _db.TestasIrasai.Add(model);
            await _db.SaveChangesAsync();
            return CreatedAtAction(nameof(Get), new { testasid = model.Testasid, irasid = model.Irasasid }, model);
        }

        [HttpPut("{testasid}/{irasasid}")]
        public async Task<IActionResult> Update(int testasid, int irasid, TestasIrasas model)
        {
            if (testasid != model.Testasid || irasid != model.Irasasid) return BadRequest();
            _db.Entry(model).State = EntityState.Modified;
            await _db.SaveChangesAsync();
            return NoContent();
        }

        [HttpDelete("{testasid}/{irasasid}")]
        public async Task<IActionResult> Delete(int testasid, int irasid)
        {
            var item = await _db.TestasIrasai.FindAsync(testasid, irasid);
            if (item == null) return NotFound();
            _db.TestasIrasai.Remove(item);
            await _db.SaveChangesAsync();
            return NoContent();
        }
    }
}
