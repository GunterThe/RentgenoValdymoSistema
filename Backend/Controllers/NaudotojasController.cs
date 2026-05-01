using System;
using System.Collections.Generic;
using System.IdentityModel.Tokens.Jwt;
using System.Linq;
using System.Security.Claims;
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

        public sealed class CreateUserRequest
        {
            public string Vardas { get; set; } = string.Empty;
            public string Pavarde { get; set; } = string.Empty;
            public DateTime GimimoData { get; set; }
            public bool Adminas { get; set; }
            public string Password { get; set; } = string.Empty;
        }

        public sealed class ChangePasswordRequest
        {
            public string CurrentPassword { get; set; } = string.Empty;
            public string NewPassword { get; set; } = string.Empty;
        }

        public sealed class AdminSetPasswordRequest
        {
            public string NewPassword { get; set; } = string.Empty;
        }

        public sealed class NaudotojasListItem
        {
            public Guid Id { get; set; }
            public string Vardas { get; set; } = string.Empty;
            public string Pavarde { get; set; } = string.Empty;
            public string PrisijungimoId { get; set; } = string.Empty;
            public bool Adminas { get; set; }
        }

        private Guid? TryGetCurrentUserId()
        {
            var idStr = User.FindFirstValue(ClaimTypes.NameIdentifier)
                        ?? User.FindFirstValue(JwtRegisteredClaimNames.Sub)
                        ?? User.FindFirstValue("sub");
            if (Guid.TryParse(idStr, out var id)) return id;
            return null;
        }

        private static DateTime EnsureUtc(DateTime dt)
        {
            return dt.Kind switch
            {
                DateTimeKind.Utc => dt,
                DateTimeKind.Local => dt.ToUniversalTime(),
                DateTimeKind.Unspecified => DateTime.SpecifyKind(dt, DateTimeKind.Local).ToUniversalTime(),
                _ => DateTime.SpecifyKind(dt, DateTimeKind.Utc)
            };
        }

        private bool IsAdmin() => User.HasClaim("admin", bool.TrueString);

        private bool IsSuperAdmin() => User.HasClaim("superadmin", bool.TrueString);

        private static bool IsPasswordAcceptable(string password)
        {
            return !string.IsNullOrWhiteSpace(password) && password.Trim().Length >= 6;
        }

        private async Task RevokeAllRefreshTokens(Guid userId)
        {
            var tokens = await _db.RefreshTokens
                .Where(t => t.NaudotojasId == userId && t.Revoked == null)
                .ToListAsync();
            if (tokens.Count == 0) return;
            var now = DateTime.UtcNow;
            foreach (var t in tokens) t.Revoked = now;
        }

        [HttpGet]
        [Authorize(Policy = "AdminOnly")]
        public async Task<ActionResult<IEnumerable<NaudotojasListItem>>> GetAll()
        {
            var list = await _db.Naudotojai
                .Select(u => new NaudotojasListItem
                {
                    Id = u.Id,
                    Vardas = u.Vardas,
                    Pavarde = u.Pavarde,
                    PrisijungimoId = u.PrisijungimoId,
                    Adminas = u.Adminas
                })
                .ToListAsync();
            return Ok(list);
        }

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
        public async Task<ActionResult<NaudotojasListItem>> Create([FromBody] CreateUserRequest req)
        {
            var canCreateAdmin = IsSuperAdmin();
            var vardas = (req.Vardas ?? string.Empty).Trim();
            var pavarde = (req.Pavarde ?? string.Empty).Trim();
            var password = (req.Password ?? string.Empty).Trim();

            if (string.IsNullOrWhiteSpace(vardas) || string.IsNullOrWhiteSpace(pavarde))
            {
                return BadRequest(new { message = "Vardas ir pavardė yra būtini" });
            }
            if (!IsPasswordAcceptable(password))
            {
                return BadRequest(new { message = "Slaptažodis turi būti bent 6 simboliai" });
            }

            var suffix = Guid.NewGuid().ToString("N").Substring(0, 3);
            var prisijungimoId = $"{vardas.ToLowerInvariant().Replace(" ", "")}.{pavarde.ToLowerInvariant().Replace(" ", "")}.{suffix}";

            var user = new Naudotojas
            {
                Id = Guid.NewGuid(),
                Vardas = vardas,
                Pavarde = pavarde,
                GimimoData = EnsureUtc(req.GimimoData.Date),
                Adminas = canCreateAdmin && req.Adminas,
                PrisijungimoId = prisijungimoId,
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(password)
            };

            _db.Naudotojai.Add(user);
            await _db.SaveChangesAsync();

            var dto = new NaudotojasListItem
            {
                Id = user.Id,
                Vardas = user.Vardas,
                Pavarde = user.Pavarde,
                PrisijungimoId = user.PrisijungimoId,
                Adminas = user.Adminas
            };

            return CreatedAtAction(nameof(Get), new { id = user.Id }, dto);
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
            var currentUserId = TryGetCurrentUserId();
            if (currentUserId == null)
            {
                return Unauthorized(new { message = "Invalid user context" });
            }

            var isSuperAdmin = IsSuperAdmin();
            if (!IsAdmin() && !isSuperAdmin && id != currentUserId.Value)
            {
                return Forbid();
            }

            var user = await _db.Naudotojai.FindAsync(id);
            if (user == null) return NotFound();

            // Admins can’t change other admins’ passwords (unless superadmin).
            if (!isSuperAdmin && id != currentUserId.Value && user.Adminas)
            {
                return Forbid();
            }

            var currentPassword = (req.CurrentPassword ?? string.Empty).Trim();
            var newPassword = (req.NewPassword ?? string.Empty).Trim();
            if (string.IsNullOrWhiteSpace(currentPassword) || string.IsNullOrWhiteSpace(newPassword))
            {
                return BadRequest(new { message = "Dabartinis ir naujas slaptažodis yra būtini" });
            }

            if (!IsPasswordAcceptable(newPassword))
            {
                return BadRequest(new { message = "Naujas slaptažodis turi būti bent 6 simboliai" });
            }

            if (!BCrypt.Net.BCrypt.Verify(currentPassword, user.PasswordHash))
            {
                return Unauthorized(new { message = "Dabartinis slaptažodis yra neteisingas" });
            }
            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(newPassword);
            user.MustChangePassword = false;
            await RevokeAllRefreshTokens(user.Id);
            await _db.SaveChangesAsync();
            return NoContent();
        }

        [HttpPut("setPassword/{id:guid}")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> AdminSetPassword(Guid id, [FromBody] AdminSetPasswordRequest req)
        {
            var currentUserId = TryGetCurrentUserId();
            if (currentUserId == null)
            {
                return Unauthorized(new { message = "Invalid user context" });
            }

            var newPassword = (req.NewPassword ?? string.Empty).Trim();
            if (!IsPasswordAcceptable(newPassword))
            {
                return BadRequest(new { message = "Naujas slaptažodis turi būti bent 6 simboliai" });
            }

            var user = await _db.Naudotojai.FindAsync(id);
            if (user == null) return NotFound();

            // Admins can’t reset other admins’ passwords (unless superadmin).
            if (!IsSuperAdmin() && id != currentUserId.Value && user.Adminas)
            {
                return Forbid();
            }

            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(newPassword);
            user.MustChangePassword = true;
            await RevokeAllRefreshTokens(user.Id);
            await _db.SaveChangesAsync();
            return NoContent();
        }

        [HttpPut("toggleAdmin/{id:guid}")]    
        [Authorize(Policy = "SuperAdminOnly")]
        public async Task<IActionResult> ToggleAdmin(Guid id)
        {
            var user = await _db.Naudotojai.FindAsync(id);
            if (user == null) return NotFound();

            user.Adminas = !user.Adminas;
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
