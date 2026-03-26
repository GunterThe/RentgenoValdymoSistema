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
	public class SablonasController : ControllerBase
	{
		private readonly AppDbContext _db;
		public SablonasController(AppDbContext db) => _db = db;

		[HttpGet]
		public async Task<ActionResult<IEnumerable<Sablonas>>> GetAll()
		{
			return await _db.Sablonai.AsNoTracking().ToListAsync();
		}

		[HttpGet("{id:int}")]
		public async Task<ActionResult<Sablonas>> GetById(int id)
		{
			var item = await _db.Sablonai.AsNoTracking().FirstOrDefaultAsync(s => s.Id == id);
			if (item == null) return NotFound();
			return item;
		}

		[HttpPost]
		[Authorize(Policy = "AdminOnly")]
		public async Task<ActionResult<Sablonas>> Create(Sablonas model)
		{
			if (string.IsNullOrWhiteSpace(model.Pavadinimas))
				return BadRequest(new { message = "Pavadinimas is required" });

			_db.Sablonai.Add(model);
			await _db.SaveChangesAsync();
			return CreatedAtAction(nameof(GetById), new { id = model.Id }, model);
		}

		[HttpPut("{id:int}")]
		[Authorize(Policy = "AdminOnly")]
		public async Task<IActionResult> Update(int id, Sablonas model)
		{
			if (id != model.Id) return BadRequest();
			if (string.IsNullOrWhiteSpace(model.Pavadinimas))
				return BadRequest(new { message = "Pavadinimas is required" });

			var existing = await _db.Sablonai.FirstOrDefaultAsync(s => s.Id == id);
			if (existing == null) return NotFound();

			existing.Pavadinimas = model.Pavadinimas;
			await _db.SaveChangesAsync();
			return NoContent();
		}

		[HttpDelete("{id:int}")]
		[Authorize(Policy = "AdminOnly")]
		public async Task<IActionResult> Delete(int id)
		{
			var existing = await _db.Sablonai.FirstOrDefaultAsync(s => s.Id == id);
			if (existing == null) return NotFound();

			_db.Sablonai.Remove(existing);
			await _db.SaveChangesAsync();
			return NoContent();
		}
	}
}
