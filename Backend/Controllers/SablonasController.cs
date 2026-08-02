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

		[HttpPost("{id:int}/copy")]
		[Authorize(Policy = "AdminOnly")]
		public async Task<ActionResult<Sablonas>> Copy(int id, [FromQuery] string? newName)
		{
			var original = await _db.Sablonai
				.Include(s => s.Testai).ThenInclude(st => st.Testas)
				.AsTracking()
				.FirstOrDefaultAsync(s => s.Id == id);
			if (original == null) return NotFound();

			using var tran = await _db.Database.BeginTransactionAsync();
			try
			{
				var copy = new Sablonas
				{
					Pavadinimas = string.IsNullOrWhiteSpace(newName) ? original.Pavadinimas + " - kopija" : newName
				};
				_db.Sablonai.Add(copy);
				await _db.SaveChangesAsync();

				// Copy each associated Testas and its ZingsnisTemplate rows
				foreach (var st in original.Testai.OrderBy(x => x.Eile))
				{
					var oldTestas = st.Testas;
					if (oldTestas == null)
					{
						oldTestas = await _db.Testai.AsNoTracking().FirstOrDefaultAsync(t => t.Id == st.Testasid);
						if (oldTestas == null) continue;
					}

					int newTestasId;
					await using (var cmd = _db.Database.GetDbConnection().CreateCommand())
					{
						if (cmd.Connection!.State != System.Data.ConnectionState.Open)
							await cmd.Connection.OpenAsync();

						if (oldTestas.Tipas == null)
						{
							cmd.CommandText = @"INSERT INTO public.testas (testotekstas, tipas)
							VALUES (@text, NULL)
							RETURNING id;";
						}
						else
						{
							cmd.CommandText = @"INSERT INTO public.testas (testotekstas, tipas)
							VALUES (@text, (@tipas)::public.testotipas)
							RETURNING id;";
							var pgEnumValue = GetPgEnumName(oldTestas.Tipas.Value);
							cmd.Parameters.Add(new NpgsqlParameter("tipas", pgEnumValue));
						}

						cmd.Parameters.Add(new NpgsqlParameter("text", oldTestas.Testotekstas));
						var scalar = await cmd.ExecuteScalarAsync();
						newTestasId = scalar == null ? 0 : Convert.ToInt32(scalar);
					}

					var newTestas = await _db.Testai.AsNoTracking().FirstAsync(t => t.Id == newTestasId);

					// link to new sablonas
					var newLink = new SablonasTestas
					{
						Sablonasid = copy.Id,
						Testasid = newTestas.Id,
						Eile = st.Eile
					};
					_db.SablonasTestai.Add(newLink);

					// copy zingsnis templates for this test
					var templates = await _db.ZingsnisTemplate.Where(z => z.TestasId == oldTestas.Id).AsNoTracking().ToListAsync();
					foreach (var tpl in templates)
					{
						var newTpl = new ZingsnisTemplate
						{
							Pavadinimas = tpl.Pavadinimas,
							Aprasymas = tpl.Aprasymas,
							TestasId = newTestas.Id,
							Eile = tpl.Eile,
							KomentarasPrivalomas = tpl.KomentarasPrivalomas,
							NuotraukaPrivaloma = tpl.NuotraukaPrivaloma
						};
						_db.ZingsnisTemplate.Add(newTpl);
					}
					await _db.SaveChangesAsync();
				}

				await tran.CommitAsync();
				return CreatedAtAction(nameof(GetById), new { id = copy.Id }, copy);
			}
			catch
			{
				await tran.RollbackAsync();
				throw;
			}
		}

		private static string GetPgEnumName<TEnum>(TEnum value)
			where TEnum : struct, System.Enum
		{
			var member = typeof(TEnum).GetMember(value.ToString())[0];
			var attr = member.GetCustomAttribute<PgNameAttribute>();
			return attr?.PgName ?? value.ToString();
		}
	}
}
