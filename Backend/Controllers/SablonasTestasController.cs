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

		private static int Clamp(int value, int min, int max)
		{
			if (value < min) return min;
			if (value > max) return max;
			return value;
		}

		private static bool NormalizeEileInPlace(List<SablonasTestas> items)
		{
			var changed = false;
			for (var i = 0; i < items.Count; i++)
			{
				var desired = i + 1;
				if (items[i].Eile != desired)
				{
					items[i].Eile = desired;
					changed = true;
				}
			}
			return changed;
		}

		[HttpGet]
		public async Task<ActionResult<IEnumerable<SablonasTestas>>> GetAll()
		{
			return await _db.SablonasTestai
				.AsNoTracking()
				.OrderBy(x => x.Sablonasid)
				.ThenBy(x => x.Eile)
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

			if (model.Eile < 1)
			{
				var maxEile = await _db.SablonasTestai
					.Where(x => x.Sablonasid == model.Sablonasid)
					.Select(x => (int?)x.Eile)
					.MaxAsync() ?? 0;
				model.Eile = maxEile + 1;
			}

			_db.SablonasTestai.Add(model);
			await _db.SaveChangesAsync();
			return CreatedAtAction(
				nameof(GetById),
				new { sablonasId = model.Sablonasid, testasId = model.Testasid },
				model
			);
		}

		[HttpPut("{sablonasId:int}/{testasId:int}")]
		[Authorize(Policy = "AdminOnly")]
		public async Task<IActionResult> Update(int sablonasId, int testasId, SablonasTestas model)
		{
			if (model.Sablonasid != 0 && model.Sablonasid != sablonasId)
				return BadRequest(new { message = "Route sablonasId does not match payload." });
			if (model.Testasid != 0 && model.Testasid != testasId)
				return BadRequest(new { message = "Route testasId does not match payload." });

			var items = await _db.SablonasTestai
				.Where(x => x.Sablonasid == sablonasId)
				.OrderBy(x => x.Eile)
				.ThenBy(x => x.Testasid)
				.ToListAsync();

			var existing = items.FirstOrDefault(x => x.Testasid == testasId);
			if (existing == null) return NotFound();

			var normalizedChanged = NormalizeEileInPlace(items);

			var requested = model.Eile;
			if (requested < 1)
			{
				if (normalizedChanged) await _db.SaveChangesAsync();
				return NoContent();
			}

			requested = Clamp(requested, 1, items.Count);
			var current = existing.Eile;
			if (requested == current)
			{
				if (normalizedChanged) await _db.SaveChangesAsync();
				return NoContent();
			}

			if (requested > current)
			{
				foreach (var x in items)
				{
					if (x.Testasid == testasId) continue;
					if (x.Eile > current && x.Eile <= requested) x.Eile -= 1;
				}
				existing.Eile = requested;
			}
			else
			{
				foreach (var x in items)
				{
					if (x.Testasid == testasId) continue;
					if (x.Eile >= requested && x.Eile < current) x.Eile += 1;
				}
				existing.Eile = requested;
			}

			await _db.SaveChangesAsync();
			return NoContent();
		}

		[HttpDelete("{sablonasId:int}/{testasId:int}")]
		[Authorize(Policy = "AdminOnly")]
		public async Task<IActionResult> Delete(int sablonasId, int testasId)
		{
			var items = await _db.SablonasTestai
				.Where(x => x.Sablonasid == sablonasId)
				.OrderBy(x => x.Eile)
				.ThenBy(x => x.Testasid)
				.ToListAsync();

			var existing = items.FirstOrDefault(x => x.Testasid == testasId);
			if (existing == null) return NotFound();

			NormalizeEileInPlace(items);
			_db.SablonasTestai.Remove(existing);
			items.Remove(existing);
			NormalizeEileInPlace(items);

			await _db.SaveChangesAsync();
			return NoContent();
		}
	}
}
