using System;
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
    public class NaudotojasController : ControllerBase
    {
        private readonly AppDbContext _db;
        public NaudotojasController(AppDbContext db) => _db = db;

        public sealed class ChangePasswordRequest
        {
            public string CurrentPassword { get; set; } = string.Empty;
            public string NewPassword { get; set; } = string.Empty;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<Naudotojas>>> GetAll() => await _db.Naudotojai.ToListAsync();

        [HttpGet("{id}")]
        public async Task<ActionResult<Naudotojas>> Get(Guid id)
        {
            var item = await _db.Naudotojai.FindAsync(id);
            if (item == null) return NotFound();
            item.PasswordHash = "";
            item.PrisijungimoId = "";
            item.Adminas = false;
            return item;
        }

        [HttpPost]
        [Authorize(Policy = "AdminOnly")]
        public async Task<ActionResult<Naudotojas>> Create(Naudotojas naudotojas)
        {
            if (naudotojas.Id == Guid.Empty) naudotojas.Id = Guid.NewGuid();
            naudotojas.PasswordHash = BCrypt.Net.BCrypt.HashPassword(naudotojas.PasswordHash);
            naudotojas.PrisijungimoId = naudotojas.Vardas.ToLower() + "." + naudotojas.Pavarde.ToLower() + "." + Guid.NewGuid().ToString("N").Substring(0, 3);
            naudotojas.Id = Guid.NewGuid();
            _db.Naudotojai.Add(naudotojas);
            await _db.SaveChangesAsync();
            return CreatedAtAction(nameof(Get), new { id = naudotojas.Id }, naudotojas);
        }

        [HttpPut("{id}")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> Update(Guid id, Naudotojas naudotojas)
        {
            if (id != naudotojas.Id) return BadRequest();
            _db.Entry(naudotojas).State = EntityState.Modified;
            await _db.SaveChangesAsync();
            return NoContent();
        }
        [HttpPut("changePassword/{id:guid}")]
        public async Task<IActionResult> ChangePassword(Guid id, [FromBody] ChangePasswordRequest req)
        {
            var user = await _db.Naudotojai.FindAsync(id);
            if (user == null) return NotFound();

            var currentPassword = (req.CurrentPassword ?? string.Empty).Trim();
            var newPassword = (req.NewPassword ?? string.Empty).Trim();
            if (string.IsNullOrWhiteSpace(currentPassword) || string.IsNullOrWhiteSpace(newPassword))
            {
                return BadRequest(new { message = "CurrentPassword and NewPassword are required" });
            }

            if (!BCrypt.Net.BCrypt.Verify(currentPassword, user.PasswordHash))
            {
                return Unauthorized(new { message = "Current password is incorrect" });
            }
            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(newPassword);
            _db.Entry(user).State = EntityState.Modified;
            await _db.SaveChangesAsync();
            return NoContent();
        }

        [HttpDelete("{id}")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> Delete(Guid id)
        {
            var item = await _db.Naudotojai.FindAsync(id);
            if (item == null) return NotFound();
            _db.Naudotojai.Remove(item);
            await _db.SaveChangesAsync();
            return NoContent();
        }
    }
}
