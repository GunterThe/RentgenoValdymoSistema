using System.Collections.Generic;
using System.Threading.Tasks;
using Backend.Data;
using Backend.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Linq;
using System.Reflection;
using Npgsql;
using NpgsqlTypes;
using System;

namespace Backend.Controllers
{
	[ApiController]
	[Authorize]
	[Route("api/[controller]")]
	public class FATController : ControllerBase
	{
		private readonly AppDbContext _db;
		public FATController(AppDbContext db) => _db = db;

		[HttpGet]
		public async Task<ActionResult<IEnumerable<FAT>>> GetAll()
		{
			return await _db.FATs.AsNoTracking().ToListAsync();
		}

		[HttpGet("{id:int}")]
		public async Task<ActionResult<FAT>> GetById(int id)
		{
			var item = await _db.FATs.AsNoTracking().FirstOrDefaultAsync(s => s.Id == id);
			if (item == null) return NotFound();
			return item;
		}

		[HttpPost]
		[Authorize(Policy = "AdminOnly")]
		public async Task<ActionResult<FAT>> Create(FAT model)
		{
			if (string.IsNullOrWhiteSpace(model.Title))
				return BadRequest(new { message = "Title is required" });

			_db.FATs.Add(model);
			await _db.SaveChangesAsync();
			return CreatedAtAction(nameof(GetById), new { id = model.Id }, model);
		}

		[HttpPut("{id:int}")]
		[Authorize(Policy = "AdminOnly")]
		public async Task<IActionResult> Update(int id, FAT model)
		{
			if (id != model.Id) return BadRequest();
			if (string.IsNullOrWhiteSpace(model.Title))
				return BadRequest(new { message = "Title is required" });

			var existing = await _db.FATs.FirstOrDefaultAsync(s => s.Id == id);
			if (existing == null) return NotFound();

			existing.Title = model.Title;
			await _db.SaveChangesAsync();
			return NoContent();
		}

		[HttpDelete("{id:int}")]
		[Authorize(Policy = "AdminOnly")]
		public async Task<IActionResult> Delete(int id)
		{
			var existing = await _db.FATs.FirstOrDefaultAsync(s => s.Id == id);
			if (existing == null) return NotFound();

			_db.FATs.Remove(existing);
			await _db.SaveChangesAsync();
			return NoContent();
		}
	}
}
