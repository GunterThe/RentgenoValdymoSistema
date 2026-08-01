using System.Collections.Generic;
using System.Threading.Tasks;
using Backend.Data;
using Backend.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authorization;

namespace Backend.Controllers
{
	[ApiController]
	[Authorize]
	[Route("api/[controller]")]
	public class HeaderController : ControllerBase
	{
		private readonly AppDbContext _db;
		public HeaderController(AppDbContext db) => _db = db;

		[HttpGet]
		public async Task<ActionResult<IEnumerable<Header>>> GetAll() =>
			await _db.Headers.ToListAsync();

		[HttpGet("{id}")]
		public async Task<ActionResult<Header>> Get(int id)
		{
			var item = await _db.Headers.FindAsync(id);
			if (item == null) return NotFound();
			return item;
		}

		[HttpPost]
		[Authorize(Policy = "AdminOnly")]
		public async Task<ActionResult<Header>> Create(Header header)
		{
			_db.Headers.Add(header);
			await _db.SaveChangesAsync();
			return CreatedAtAction(nameof(Get), new { id = header.Id }, header);
		}

		[HttpPut("{id}")]
		[Authorize(Policy = "AdminOnly")]
		public async Task<IActionResult> Update(int id, Header header)
		{
			if (id != header.Id) return BadRequest();

			var existing = await _db.Headers.FirstOrDefaultAsync(h => h.Id == id);
			if (existing == null) return NotFound();

			existing.Text = header.Text;

			try
			{
				await _db.SaveChangesAsync();
			}
			catch (DbUpdateConcurrencyException)
			{
				if (!await _db.Headers.AnyAsync(e => e.Id == id)) return NotFound();
				throw;
			}

			return NoContent();
		}

		[HttpDelete("{id}")]
		[Authorize(Policy = "AdminOnly")]
		public async Task<IActionResult> Delete(int id)
		{
			var item = await _db.Headers.FindAsync(id);
			if (item == null) return NotFound();
			_db.Headers.Remove(item);
			await _db.SaveChangesAsync();
			return NoContent();
		}
	}
}
