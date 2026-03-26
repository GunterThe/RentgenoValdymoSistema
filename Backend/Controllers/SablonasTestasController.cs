using System.Collections.Generic;
using System.Linq;
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
	public class SablonasTestasController : ControllerBase
	{
		private readonly AppDbContext _db;
		public SablonasTestasController(AppDbContext db) => _db = db;

		[HttpGet]
		public async Task<ActionResult<IEnumerable<SablonasTestas>>> GetAll()
		{
			return await _db.SablonasTestai
				.AsNoTracking()
				.OrderBy(x => x.Sablonasid)
				.ThenBy(x => x.Testasid)
				.ToListAsync();
		}

		[HttpGet("{sablonasId:int}/{testasId:int}")]
		public async Task<ActionResult<SablonasTestas>> GetById(int sablonasId, int testasId)
		{
			var item = await _db.SablonasTestai
				.AsNoTracking()
				.FirstOrDefaultAsync(x => x.Sablonasid == sablonasId && x.Testasid == testasId);
			if (item == null) return NotFound();
			return item;
		}

		[HttpPost]
		[Authorize(Policy = "AdminOnly")]
		public async Task<ActionResult<SablonasTestas>> Create(SablonasTestas model)
		{
			var sablonasExists = await _db.Sablonai.AsNoTracking().AnyAsync(s => s.Id == model.Sablonasid);
			if (!sablonasExists)
				return BadRequest(new { message = "Sablonas does not exist" });

			var testasExists = await _db.Testai.AsNoTracking().AnyAsync(t => t.Id == model.Testasid);
			if (!testasExists)
				return BadRequest(new { message = "Testas does not exist" });

			var exists = await _db.SablonasTestai.AsNoTracking().AnyAsync(x =>
				x.Sablonasid == model.Sablonasid && x.Testasid == model.Testasid);
			if (exists) return Conflict(new { message = "Link already exists" });

			_db.SablonasTestai.Add(model);
			await _db.SaveChangesAsync();
			return CreatedAtAction(
				nameof(GetById),
				new { sablonasId = model.Sablonasid, testasId = model.Testasid },
				model
			);
		}

		[HttpDelete("{sablonasId:int}/{testasId:int}")]
		[Authorize(Policy = "AdminOnly")]
		public async Task<IActionResult> Delete(int sablonasId, int testasId)
		{
			var existing = await _db.SablonasTestai
				.FirstOrDefaultAsync(x => x.Sablonasid == sablonasId && x.Testasid == testasId);
			if (existing == null) return NotFound();

			_db.SablonasTestai.Remove(existing);
			await _db.SaveChangesAsync();
			return NoContent();
		}
	}
}
