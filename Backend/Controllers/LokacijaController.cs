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
	public class LokacijaController : ControllerBase
	{
		private readonly AppDbContext _db;
		public LokacijaController(AppDbContext db) => _db = db;

		[HttpGet]
		public async Task<ActionResult<IEnumerable<Lokacija>>> GetAll()
		{
			return await _db.Lokacijos.AsNoTracking().ToListAsync();
		}

		[HttpGet("{id:int}")]
		public async Task<ActionResult<Lokacija>> GetById(int id)
		{
			var item = await _db.Lokacijos.AsNoTracking().FirstOrDefaultAsync(l => l.Id == id);
			if (item == null) return NotFound();
			return item;
		}

		[HttpPost]
		[Authorize(Policy = "AdminOnly")]
		public async Task<ActionResult<Lokacija>> Create(Lokacija model)
		{
			if (string.IsNullOrWhiteSpace(model.Pavadinimas))
				return BadRequest(new { message = "Pavadinimas is required" });

			_db.Lokacijos.Add(model);
			await _db.SaveChangesAsync();
			return CreatedAtAction(nameof(GetById), new { id = model.Id }, model);
		}

		[HttpPut("{id:int}")]
		[Authorize(Policy = "AdminOnly")]
		public async Task<IActionResult> Update(int id, Lokacija model)
		{
			if (id != model.Id) return BadRequest();
			if (string.IsNullOrWhiteSpace(model.Pavadinimas))
				return BadRequest(new { message = "Pavadinimas is required" });

			var existing = await _db.Lokacijos.FirstOrDefaultAsync(l => l.Id == id);
			if (existing == null) return NotFound();

			existing.Pavadinimas = model.Pavadinimas;
			await _db.SaveChangesAsync();
			return NoContent();
		}

		[HttpDelete("{id:int}")]
		[Authorize(Policy = "AdminOnly")]
		public async Task<IActionResult> Delete(int id)
		{
			var existing = await _db.Lokacijos.FirstOrDefaultAsync(l => l.Id == id);
			if (existing == null) return NotFound();

			var inUse = await _db.Irasai.AsNoTracking().AnyAsync(i => i.LokacijaId == id);
			if (inUse)
				return BadRequest(new { message = "Lokacija is in use by at least one irasas" });

			_db.Lokacijos.Remove(existing);
			await _db.SaveChangesAsync();
			return NoContent();
		}
	}
}

