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
	public class FATRowController : ControllerBase
	{
		private readonly AppDbContext _db;
		public FATRowController(AppDbContext db) => _db = db;

		private static int Clamp(int value, int min, int max)
		{
			if (value < min) return min;
			if (value > max) return max;
			return value;
		}

		private static bool NormalizeEileInPlace(List<FATRow> items)
		{
			var changed = false;
			for (var i = 0; i < items.Count; i++)
			{
				var desired = i + 1;
				if (items[i].Order != desired)
				{
					items[i].Order = desired;
					changed = true;
				}
			}
			return changed;
		}

		[HttpGet]
		public async Task<ActionResult<IEnumerable<FATRow>>> GetAll()
		{
			return await _db.FATRows
				.AsNoTracking()
				.OrderBy(x => x.Fatid)
				.ThenBy(x => x.Rowid)
                .ThenBy(x => x.Order)
				.ToListAsync();
		}

		[HttpGet("{fatId:int}/{rowId:int}")]
		public async Task<ActionResult<FATRow>> GetById(int fatId, int rowId)
		{
			var item = await _db.FATRows
				.AsNoTracking()
				.FirstOrDefaultAsync(x => x.Fatid == fatId && x.Rowid == rowId);
			if (item == null) return NotFound();
			return item;
		}

		[HttpPost]
		[Authorize(Policy = "AdminOnly")]
		public async Task<ActionResult<FATRow>> Create(FATRow model)
		{
			var fatExists = await _db.FATs.AsNoTracking().AnyAsync(s => s.Id == model.Fatid);
			if (!fatExists)
				return BadRequest(new { message = "FAT does not exist" });

			var rowExists = await _db.Rows.AsNoTracking().AnyAsync(t => t.Id == model.Rowid);
			if (!rowExists)
				return BadRequest(new { message = "Row does not exist" });

			var exists = await _db.FATRows.AsNoTracking().AnyAsync(x =>
				x.Fatid == model.Fatid && x.Rowid == model.Rowid);
			if (exists) return Conflict(new { message = "Link already exists" });

			if (model.Order < 1)
			{
				var maxOrder = await _db.FATRows
					.Where(x => x.Fatid == model.Fatid)
					.Select(x => (int?)x.Order)
					.MaxAsync() ?? 0;
				model.Order = maxOrder + 1;
			}

			_db.FATRows.Add(model);
			await _db.SaveChangesAsync();
			return CreatedAtAction(
				nameof(GetById),
				new { fatId = model.Fatid, rowId = model.Rowid },
				model
			);
		}

		[HttpPut("{fatId:int}/{rowId:int}")]
		[Authorize(Policy = "AdminOnly")]
		public async Task<IActionResult> Update(int fatId, int rowId, FATRow model)
		{
			if (model.Fatid != 0 && model.Fatid != fatId)
				return BadRequest(new { message = "Route fatId does not match payload." });
			if (model.Rowid != 0 && model.Rowid != rowId)
				return BadRequest(new { message = "Route rowId does not match payload." });

			var items = await _db.FATRows
				.Where(x => x.Fatid == fatId)
				.OrderBy(x => x.Order)
				.ThenBy(x => x.Rowid)
				.ToListAsync();

			var existing = items.FirstOrDefault(x => x.Rowid == rowId);
			if (existing == null) return NotFound();

			var normalizedChanged = NormalizeEileInPlace(items);

			var requested = model.Order;
			if (requested < 1)
			{
				if (normalizedChanged) await _db.SaveChangesAsync();
				return NoContent();
			}

			requested = Clamp(requested, 1, items.Count);
			var current = existing.Order;
			if (requested == current)
			{
				if (normalizedChanged) await _db.SaveChangesAsync();
				return NoContent();
			}

			if (requested > current)
			{
				foreach (var x in items)
				{
					if (x.Rowid == rowId) continue;
					if (x.Order > current && x.Order <= requested) x.Order -= 1;
				}
				existing.Order = requested;
			}
			else
			{
				foreach (var x in items)
				{
					if (x.Rowid == rowId) continue;
					if (x.Order >= requested && x.Order < current) x.Order += 1;
				}
				existing.Order = requested;
			}

			await _db.SaveChangesAsync();
			return NoContent();
		}

		[HttpDelete("{fatId:int}/{rowId:int}")]
		[Authorize(Policy = "AdminOnly")]
		public async Task<IActionResult> Delete(int fatId, int rowId)
		{
			var items = await _db.FATRows
				.Where(x => x.Fatid == fatId)
				.OrderBy(x => x.Order)
				.ThenBy(x => x.Rowid)
				.ToListAsync();

			var existing = items.FirstOrDefault(x => x.Rowid == rowId);
			if (existing == null) return NotFound();

			NormalizeEileInPlace(items);
			_db.FATRows.Remove(existing);
			items.Remove(existing);
			NormalizeEileInPlace(items);

			await _db.SaveChangesAsync();
			return NoContent();
		}
	}
}
