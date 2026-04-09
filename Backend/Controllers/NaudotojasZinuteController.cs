using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.IdentityModel.Tokens.Jwt;
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
    public class NaudotojasZinuteController : ControllerBase
    {
        private readonly AppDbContext _db;
        public NaudotojasZinuteController(AppDbContext db) => _db = db;

        public sealed class CreateNaudotojasZinuteRequest
        {
            public Guid NaudotojasId { get; set; }
            public int ZinuteId { get; set; }
        }

        public sealed class UpdateNaudotojasZinuteRequest
        {
            public bool Perskaityta { get; set; }
        }

        public sealed class NaudotojasZinuteDto
        {
            public Guid NaudotojasId { get; set; }
            public int ZinuteId { get; set; }
            public bool Perskaityta { get; set; }
        }

        public sealed class InboxItemDto
        {
            public int ZinuteId { get; set; }
            public string Tekstas { get; set; } = string.Empty;
            public bool Perskaityta { get; set; }
        }

        private Guid? TryGetCurrentUserId()
        {
            var idStr = User.FindFirstValue(ClaimTypes.NameIdentifier)
                        ?? User.FindFirstValue(JwtRegisteredClaimNames.Sub)
                        ?? User.FindFirstValue("sub");
            if (Guid.TryParse(idStr, out var id)) return id;
            return null;
        }

        private bool IsAdmin() => User.HasClaim("admin", bool.TrueString);

        [HttpGet]
        [Authorize(Policy = "AdminOnly")]
        public async Task<ActionResult<IEnumerable<NaudotojasZinuteDto>>> GetAll()
        {
            var list = await _db.NaudotojasZinute
                .AsNoTracking()
                .Select(nz => new NaudotojasZinuteDto
                {
                    NaudotojasId = nz.Naudotojasid,
                    ZinuteId = nz.Zinuteid,
                    Perskaityta = nz.Perskaityta,
                })
                .ToListAsync();

            return Ok(list);
        }

        [HttpGet("my")]
        public async Task<ActionResult<IEnumerable<InboxItemDto>>> MyInbox()
        {
            var currentUserId = TryGetCurrentUserId();
            if (currentUserId == null) return Unauthorized();

            var list = await _db.NaudotojasZinute
                .AsNoTracking()
                .Where(nz => nz.Naudotojasid == currentUserId.Value)
                .Include(nz => nz.Zinute)
                .OrderByDescending(nz => nz.Zinuteid)
                .Select(nz => new InboxItemDto
                {
                    ZinuteId = nz.Zinuteid,
                    Tekstas = nz.Zinute != null ? nz.Zinute.Tekstas : string.Empty,
                    Perskaityta = nz.Perskaityta,
                })
                .ToListAsync();

            return Ok(list);
        }

        [HttpGet("{naudotojasId:guid}/{zinuteId:int}")]
        public async Task<ActionResult<NaudotojasZinuteDto>> Get(Guid naudotojasId, int zinuteId)
        {
            var currentUserId = TryGetCurrentUserId();
            if (currentUserId == null) return Unauthorized();

            if (!IsAdmin() && currentUserId.Value != naudotojasId) return Forbid();

            var item = await _db.NaudotojasZinute
                .AsNoTracking()
                .FirstOrDefaultAsync(nz => nz.Naudotojasid == naudotojasId && nz.Zinuteid == zinuteId);

            if (item == null) return NotFound();

            return Ok(new NaudotojasZinuteDto
            {
                NaudotojasId = item.Naudotojasid,
                ZinuteId = item.Zinuteid,
                Perskaityta = item.Perskaityta,
            });
        }

        [HttpPost]
        [Authorize(Policy = "AdminOnly")]
        public async Task<ActionResult<NaudotojasZinuteDto>> Create([FromBody] CreateNaudotojasZinuteRequest req)
        {
            if (req.NaudotojasId == Guid.Empty) return BadRequest(new { message = "NaudotojasId yra būtinas" });
            if (req.ZinuteId <= 0) return BadRequest(new { message = "ZinuteId yra būtinas" });

            var naudotojasExists = await _db.Naudotojai.AsNoTracking().AnyAsync(n => n.Id == req.NaudotojasId);
            if (!naudotojasExists) return BadRequest(new { message = "Naudotojas neegzistuoja" });

            var zinuteExists = await _db.Zinutes.AsNoTracking().AnyAsync(z => z.Id == req.ZinuteId);
            if (!zinuteExists) return BadRequest(new { message = "Zinutė neegzistuoja" });

            var exists = await _db.NaudotojasZinute.AnyAsync(nz => nz.Naudotojasid == req.NaudotojasId && nz.Zinuteid == req.ZinuteId);
            if (exists) return Conflict(new { message = "Ryšys jau egzistuoja" });

            var link = new NaudotojasZinute
            {
                Naudotojasid = req.NaudotojasId,
                Zinuteid = req.ZinuteId,
                Perskaityta = false,
            };

            _db.NaudotojasZinute.Add(link);
            await _db.SaveChangesAsync();

            var dto = new NaudotojasZinuteDto
            {
                NaudotojasId = link.Naudotojasid,
                ZinuteId = link.Zinuteid,
                Perskaityta = link.Perskaityta,
            };

            return CreatedAtAction(nameof(Get), new { naudotojasId = dto.NaudotojasId, zinuteId = dto.ZinuteId }, dto);
        }

        [HttpPut("{naudotojasId:guid}/{zinuteId:int}")]
        public async Task<IActionResult> Update(Guid naudotojasId, int zinuteId, [FromBody] UpdateNaudotojasZinuteRequest req)
        {
            var currentUserId = TryGetCurrentUserId();
            if (currentUserId == null) return Unauthorized();

            if (!IsAdmin() && currentUserId.Value != naudotojasId) return Forbid();

            var item = await _db.NaudotojasZinute
                .FirstOrDefaultAsync(nz => nz.Naudotojasid == naudotojasId && nz.Zinuteid == zinuteId);

            if (item == null) return NotFound();

            item.Perskaityta = req.Perskaityta;
            await _db.SaveChangesAsync();

            return NoContent();
        }

        [HttpDelete("{naudotojasId:guid}/{zinuteId:int}")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> Delete(Guid naudotojasId, int zinuteId)
        {
            var item = await _db.NaudotojasZinute
                .FirstOrDefaultAsync(nz => nz.Naudotojasid == naudotojasId && nz.Zinuteid == zinuteId);

            if (item == null) return NotFound();

            _db.NaudotojasZinute.Remove(item);
            await _db.SaveChangesAsync();

            return NoContent();
        }
    }
}
