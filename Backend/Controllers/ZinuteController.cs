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
    public class ZinuteController : ControllerBase
    {
        private readonly AppDbContext _db;
        public ZinuteController(AppDbContext db) => _db = db;

        public sealed class CreateZinuteRequest
        {
            public string Tekstas { get; set; } = string.Empty;
        }

        public sealed class UpdateZinuteRequest
        {
            public string Tekstas { get; set; } = string.Empty;
        }

        [HttpGet]
        [Authorize(Policy = "AdminOnly")]
        public async Task<ActionResult<IEnumerable<Zinute>>> GetAll()
        {
            return await _db.Zinutes.AsNoTracking().ToListAsync();
        }

        [HttpGet("{id:int}")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<ActionResult<Zinute>> Get(int id)
        {
            var item = await _db.Zinutes.AsNoTracking().FirstOrDefaultAsync(z => z.Id == id);
            if (item == null) return NotFound();
            return item;
        }
        [HttpPost("sendToAdmins")]
        public async Task<ActionResult<Zinute>> SendMessageToAllAdmins([FromBody] CreateZinuteRequest req)
        {
            var tekstas = (req.Tekstas ?? string.Empty).Trim();
            if (string.IsNullOrWhiteSpace(tekstas))
            {
                return BadRequest(new { message = "Tekstas yra būtinas" });
            }

            var zinute = new Zinute { Tekstas = tekstas };
            _db.Zinutes.Add(zinute);
            await _db.SaveChangesAsync();

            var admins = await _db.Naudotojai.Where(n => n.Adminas == true).ToListAsync();
            foreach (var admin in admins)
            {
                _db.NaudotojasZinute.Add(new NaudotojasZinute
                {
                    Naudotojasid = admin.Id,
                    Zinuteid = zinute.Id,
                    Perskaityta = false
                });
            }
            await _db.SaveChangesAsync();

            return CreatedAtAction(nameof(Get), new { id = zinute.Id }, zinute);
        }

        [HttpPost]
        [Authorize(Policy = "AdminOnly")]
        public async Task<ActionResult<Zinute>> Create([FromBody] CreateZinuteRequest req)
        {
            var tekstas = (req.Tekstas ?? string.Empty).Trim();
            if (string.IsNullOrWhiteSpace(tekstas))
            {
                return BadRequest(new { message = "Tekstas yra būtinas" });
            }

            var zinute = new Zinute { Tekstas = tekstas };
            _db.Zinutes.Add(zinute);
            await _db.SaveChangesAsync();

            return CreatedAtAction(nameof(Get), new { id = zinute.Id }, zinute);
        }

        [HttpPut("{id:int}")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> Update(int id, [FromBody] UpdateZinuteRequest req)
        {
            var tekstas = (req.Tekstas ?? string.Empty).Trim();
            if (string.IsNullOrWhiteSpace(tekstas))
            {
                return BadRequest(new { message = "Tekstas yra būtinas" });
            }

            var existing = await _db.Zinutes.FirstOrDefaultAsync(z => z.Id == id);
            if (existing == null) return NotFound();

            existing.Tekstas = tekstas;
            await _db.SaveChangesAsync();
            return NoContent();
        }

        [HttpDelete("{id:int}")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> Delete(int id)
        {
            var existing = await _db.Zinutes.FirstOrDefaultAsync(z => z.Id == id);
            if (existing == null) return NotFound();

            _db.Zinutes.Remove(existing);
            await _db.SaveChangesAsync();
            return NoContent();
        }
    }
}
