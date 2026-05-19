using System.Collections.Generic;
using System;
using System.IO;
using System.Threading.Tasks;
using Backend.Data;
using Backend.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authorization;
using System.Linq;

namespace Backend.Controllers
{
    [ApiController]
    [Authorize]
    [Route("api/[controller]")]
    public class ZingsnisController : ControllerBase
    {
        private readonly AppDbContext _db;
        public ZingsnisController(AppDbContext db) => _db = db;

        private const string StatusasNepradetas = "Nepradėtas";
        private const string StatusasPabaigtas = "Pabaigtas";
        private static string StatusasAnt(string testPav, int zingsnisEile) => $"Ant {testPav} testo {zingsnisEile} žingsnio";

        private static string NormalizeKomentaras(string? s)
        {
            var t = (s ?? string.Empty).Trim();
            if (t == "-") return string.Empty;
            return t;
        }

        private static bool IsImageFileName(string? name)
        {
            if (string.IsNullOrWhiteSpace(name)) return false;
            var ext = Path.GetExtension(name).ToLowerInvariant();
            return ext is ".jpg" or ".jpeg" or ".png" or ".gif" or ".bmp" or ".webp" or ".avif" or ".heic" or ".heif" or ".tif" or ".tiff";
        }

        private async Task<bool> IsTestasIrasasFullyCompletedAsync(TestasIrasas link)
        {
            var templateIds = await _db.ZingsnisTemplate
                .AsNoTracking()
                .Where(t => t.TestasId == link.Testasid)
                .Select(t => t.Id)
                .ToListAsync();

            if (templateIds.Count == 0) return true;

            var completedTemplateIds = await _db.Zingsniai
                .AsNoTracking()
                .Where(z => z.TestasIrasasId == link.Id && z.CompletedAt != null)
                .Select(z => z.ZingsnisTemplateId)
                .Distinct()
                .ToListAsync();

            var completedSet = completedTemplateIds.ToHashSet();
            foreach (var tplId in templateIds)
            {
                if (!completedSet.Contains(tplId)) return false;
            }

            return true;
        }

        private async Task<string?> ValidateCompletionRulesAsync(Zingsnis zingsnis)
        {
            if (zingsnis.CompletedAt == null) return null;

            var template = await _db.ZingsnisTemplate
                .AsNoTracking()
                .FirstOrDefaultAsync(t => t.Id == zingsnis.ZingsnisTemplateId);
            if (template == null)
            {
                return "Nerastas žingsnio šablonas (zingsnisTemplate).";
            }

            var currentLink = await _db.TestasIrasai
                .AsNoTracking()
                .FirstOrDefaultAsync(t => t.Id == zingsnis.TestasIrasasId);
            if (currentLink == null)
            {
                return "Nerastas testas/įrašas ryšys (testasIrasas).";
            }

            // Intra-test gating: if gate steps are configured for this TestasIrasas,
            // all gate steps must be completed before completing any non-gate step.
            var gateTemplateIds = await _db.TestasIrasasPrivalomiZingsniai
                .AsNoTracking()
                .Where(x => x.TestasIrasasId == currentLink.Id)
                .Select(x => x.ZingsnisTemplateId)
                .Distinct()
                .ToListAsync();

            if (gateTemplateIds.Count > 0 && !gateTemplateIds.Contains(zingsnis.ZingsnisTemplateId))
            {
                var completedGateIds = await _db.Zingsniai
                    .AsNoTracking()
                    .Where(z => z.TestasIrasasId == currentLink.Id && z.CompletedAt != null && gateTemplateIds.Contains(z.ZingsnisTemplateId))
                    .Select(z => z.ZingsnisTemplateId)
                    .Distinct()
                    .ToListAsync();

                var completedSet = completedGateIds.ToHashSet();
                foreach (var gateTplId in gateTemplateIds)
                {
                    if (!completedSet.Contains(gateTplId))
                    {
                        return "Pirma užbaikite privalomus vartų žingsnius (pažymėtus kaip būtinius) ir tik tada tęskite kitus žingsnius.";
                    }
                }
            }

            var komentaras = NormalizeKomentaras(zingsnis.Komentaras);
            var requireComment = template.KomentarasPrivalomas;
            var requirePhoto = template.NuotraukaPrivaloma;

            var hasComment = !string.IsNullOrWhiteSpace(komentaras);
            var hasImage = false;

            if (requirePhoto)
            {
                if (zingsnis.Id <= 0)
                {
                    return "Norint užbaigti žingsnį su privaloma nuotrauka, pirmiausia sukurkite žingsnį ir prisegkite nuotrauką.";
                }

                var fileNames = await _db.PrisegtiFailai
                    .AsNoTracking()
                    .Where(p => p.ZingsnisId == zingsnis.Id)
                    .Select(p => p.FailoPav)
                    .ToListAsync();

                hasImage = fileNames.Any(IsImageFileName);
            }

            if (requireComment && requirePhoto)
            {
                if (!hasComment && !hasImage)
                {
                    return "Norint užbaigti žingsnį, reikalingas komentaras ir nuotrauka.";
                }
                if (!hasComment)
                {
                    return "Norint užbaigti žingsnį, reikalingas komentaras.";
                }
                if (!hasImage)
                {
                    return "Norint užbaigti žingsnį, reikalinga nuotrauka.";
                }
            }
            else if (requireComment)
            {
                if (!hasComment)
                {
                    return "Norint užbaigti žingsnį, reikalingas komentaras.";
                }
            }
            else if (requirePhoto)
            {
                if (!hasImage)
                {
                    return "Norint užbaigti žingsnį, reikalinga nuotrauka.";
                }
            }

            return null;
        }

        private sealed record TemplateLite(int Id, int Eile, int TestasId);

        private async Task<(string statusas, bool finished)> ComputeIrasasStatusasAsync(int irasasId)
        {
            var links = await _db.TestasIrasai
                .AsNoTracking()
                .Where(t => t.Irasasid == irasasId)
                .OrderBy(t => t.Eile)
                .ToListAsync();

            if (links.Count == 0)
            {
                return (StatusasNepradetas, false);
            }

            var linkIds = links.Select(l => l.Id).ToList();
            var started = await _db.Zingsniai.AsNoTracking().AnyAsync(z => linkIds.Contains(z.TestasIrasasId));
            if (!started)
            {
                return (StatusasNepradetas, false);
            }

            var testIds = links.Select(l => l.Testasid).Distinct().ToList();
            var templates = await _db.ZingsnisTemplate
                .AsNoTracking()
                .Where(t => testIds.Contains(t.TestasId))
                .Select(t => new TemplateLite(t.Id, t.Eile, t.TestasId))
                .ToListAsync();

            var templatesByTestId = templates
                .GroupBy(t => t.TestasId)
                .ToDictionary(g => g.Key, g => g.OrderBy(x => x.Eile).ToList());

            var zingsniai = await _db.Zingsniai
                .AsNoTracking()
                .Where(z => linkIds.Contains(z.TestasIrasasId))
                .Select(z => new { z.TestasIrasasId, z.ZingsnisTemplateId, z.CompletedAt })
                .ToListAsync();

            var completedByKey = zingsniai
                .ToDictionary(
                    z => (z.TestasIrasasId, z.ZingsnisTemplateId),
                    z => z.CompletedAt != null
                );

            foreach (var link in links)
            {
                if (!templatesByTestId.TryGetValue(link.Testasid, out var tpls) || tpls.Count == 0)
                {
                    continue;
                }

                foreach (var tpl in tpls)
                {
                    var key = (link.Id, tpl.Id);
                    var isCompleted = completedByKey.TryGetValue(key, out var v) && v;
                    var testPav = await _db.Testai.AsNoTracking().Where(t => t.Id == link.Testasid).Select(t => t.Testotekstas).FirstOrDefaultAsync();
                    if (!isCompleted && testPav != null)
                    {
                        return (StatusasAnt(testPav, tpl.Eile), false);
                    }
                }
            }

            return (StatusasPabaigtas, true);
        }

        private async Task UpdateIrasasProgressFieldsAsync(int irasasId)
        {
            var (statusas, finished) = await ComputeIrasasStatusasAsync(irasasId);
            var current = await _db.Irasai.AsNoTracking().FirstOrDefaultAsync(i => i.Id == irasasId);
            if (current == null) return;

            DateTime? pabaiga = finished
                ? (current.Pabaiga ?? DateTime.UtcNow)
                : (DateTime?)null;

            if (current.Statusas == statusas && current.Pabaiga == pabaiga) return;

            var irasas = new Irasas { Id = irasasId, Statusas = statusas, Pabaiga = pabaiga };
            _db.Irasai.Attach(irasas);
            _db.Entry(irasas).Property(i => i.Statusas).IsModified = true;
            _db.Entry(irasas).Property(i => i.Pabaiga).IsModified = true;
            await _db.SaveChangesAsync();
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

        [HttpGet]
        public async Task<ActionResult<IEnumerable<Zingsnis>>> GetAll() =>
            await _db.Zingsniai.ToListAsync();

        [HttpGet("{id}")]
        public async Task<ActionResult<Zingsnis>> Get(int id)
        {
            var item = await _db.Zingsniai.FindAsync(id);
            if (item == null) return NotFound();
            return item;
        }
        [HttpGet("getByEverything/{testasIrasasId}/{zingsnisTemplateId}")]
        public async Task<ActionResult<Zingsnis>> GetByEverything(int testasIrasasId, int zingsnisTemplateId)
        {
            var item = await _db.Zingsniai.FirstOrDefaultAsync(z => z.TestasIrasasId == testasIrasasId && z.ZingsnisTemplateId == zingsnisTemplateId);
            if (item == null) return NotFound();
            return item;
        }

        [HttpPost]
        public async Task<ActionResult<Zingsnis>> Create(Zingsnis zingsnis)
        {
            if (zingsnis.CompletedAt == null) zingsnis.Pabaigtas = false; else zingsnis.Pabaigtas = true;

            var createValidation = await ValidateCompletionRulesAsync(zingsnis);
            if (createValidation != null)
            {
                return BadRequest(createValidation);
            }

            _db.Zingsniai.Add(zingsnis);
            await _db.SaveChangesAsync();

            var link = await _db.TestasIrasai.AsNoTracking().FirstOrDefaultAsync(t => t.Id == zingsnis.TestasIrasasId);
            if (link != null)
            {
                await UpdateIrasasProgressFieldsAsync(link.Irasasid);
            }

            return CreatedAtAction(nameof(Get), new { id = zingsnis.Id }, zingsnis);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, Zingsnis zingsnis)
        {
            Zingsnis? temp = await _db.Zingsniai.AsNoTracking().FirstOrDefaultAsync(z => z.Id == id);
            if (temp == null) return NotFound();
            bool isAdmin = User.HasClaim("admin", bool.TrueString);
            if (id != zingsnis.Id) return BadRequest();
            if (zingsnis.CompletedAt == null)
            {
                if (temp == null) return NotFound();

                if (temp.CompletedAt != null && !isAdmin)
                {
                    return Forbid();
                }
            }
            else
            {
                zingsnis.Pabaigtas = true;
            }

            if (zingsnis.CompletedAt != null)
            {
                zingsnis.CompletedAt = EnsureUtc(zingsnis.CompletedAt.Value);
            }

            var validationError = await ValidateCompletionRulesAsync(zingsnis);
            if (validationError != null)
            {
                return BadRequest(validationError);
            }

            _db.Entry(zingsnis).State = EntityState.Modified;
            await _db.SaveChangesAsync();

            var link = await _db.TestasIrasai.AsNoTracking().FirstOrDefaultAsync(t => t.Id == temp.TestasIrasasId);
            if (link != null)
            {
                await UpdateIrasasProgressFieldsAsync(link.Irasasid);
            }
            return NoContent();
        }

        [HttpDelete("{id}")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> Delete(int id)
        {
            var item = await _db.Zingsniai.FindAsync(id);
            if (item == null) return NotFound();

            var link = await _db.TestasIrasai.AsNoTracking().FirstOrDefaultAsync(t => t.Id == item.TestasIrasasId);
            _db.PrisegtiFailai.RemoveRange(_db.PrisegtiFailai.Where(p => p.ZingsnisId == id));
            _db.Zingsniai.Remove(item);
            await _db.SaveChangesAsync();

            if (link != null)
            {
                await UpdateIrasasProgressFieldsAsync(link.Irasasid);
            }

            return NoContent();
        }
    }
}
