using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Backend.Data;
using Backend.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.StaticFiles;
using Microsoft.AspNetCore.Authorization;

namespace Backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class PrisegtasFailasController : ControllerBase
    {
        private readonly AppDbContext _db;
        public PrisegtasFailasController(AppDbContext db) => _db = db;

        private static bool IsImageFileName(string? name)
        {
            if (string.IsNullOrWhiteSpace(name)) return false;
            var ext = Path.GetExtension(name).ToLowerInvariant();
            return ext is ".jpg" or ".jpeg" or ".png" or ".gif" or ".bmp" or ".webp" or ".avif" or ".heic" or ".heif" or ".tif" or ".tiff";
        }

        private static void TryDeletePhysicalFile(string? relativePath)
        {
            if (string.IsNullOrWhiteSpace(relativePath)) return;
            try
            {
                var path = Path.Combine(Directory.GetCurrentDirectory(), relativePath);
                if (System.IO.File.Exists(path))
                    System.IO.File.Delete(path);
            }
            catch
            {
            }
        }

        private static string? ResolveAbsolutePath(string? storedRelativePath)
        {
            if (string.IsNullOrWhiteSpace(storedRelativePath)) return null;
            return Path.Combine(Directory.GetCurrentDirectory(), storedRelativePath);
        }

        private static string ResolveContentType(string fileName)
        {
            var provider = new FileExtensionContentTypeProvider();
            if (provider.TryGetContentType(fileName, out var contentType))
                return contentType;
            return "application/octet-stream";
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<PrisegtasFailas>>> GetAll() => await _db.PrisegtiFailai.ToListAsync();

        [HttpGet("{id}")]
        public async Task<ActionResult<PrisegtasFailas>> Get(Guid id)
        {
            var item = await _db.PrisegtiFailai.FindAsync(id);
            if (item == null) return NotFound();
            return item;
        }

        [HttpGet("byZingsnis/{zingsnisid}")]
        public async Task<ActionResult<IEnumerable<PrisegtasFailas>>> GetByZingsnis(int zingsnisid)
        {
            var list = await _db.PrisegtiFailai
                .Where(p => p.ZingsnisId == zingsnisid)
                .OrderByDescending(p => p.SukurimoLaikas)
                .ToListAsync();
            return list;
        }

        [HttpGet("byZingsnisTemplate/{templateId}")]
        public async Task<ActionResult<IEnumerable<PrisegtasFailas>>> GetByZingsnisTemplate(int templateId)
        {
            var list = await _db.PrisegtiFailai
                .Where(p => p.ZingsnisTemplateId == templateId)
                .OrderByDescending(p => p.SukurimoLaikas)
                .ToListAsync();
            return list;
        }

        [HttpGet("file/{id}")]
        [Authorize]
        public async Task<IActionResult> GetFile(Guid id)
        {
            var item = await _db.PrisegtiFailai.FindAsync(id);
            if (item == null) return NotFound();

            var path = ResolveAbsolutePath(item.Nuoroda);
            if (path == null || !System.IO.File.Exists(path)) return NotFound();

            var contentType = ResolveContentType(item.FailoPav ?? Path.GetFileName(path));
            return PhysicalFile(path, contentType, enableRangeProcessing: true);
        }

        [HttpGet("download/{id}")]
        [Authorize]
        public async Task<IActionResult> Download(Guid id)
        {
            var item = await _db.PrisegtiFailai.FindAsync(id);
            if (item == null) return NotFound();

            var path = ResolveAbsolutePath(item.Nuoroda);
            if (path == null || !System.IO.File.Exists(path)) return NotFound();

            var fileName = item.FailoPav ?? Path.GetFileName(path);
            var contentType = ResolveContentType(fileName);
            return PhysicalFile(path, contentType, fileName, enableRangeProcessing: true);
        }

        [HttpPost]
        [Authorize]
        public async Task<ActionResult<PrisegtasFailas>> Create(PrisegtasFailas model)
        {
            _db.PrisegtiFailai.Add(model);
            await _db.SaveChangesAsync();
            return CreatedAtAction(nameof(Get), new { id = model.Id }, model);
        }

        [HttpPost("upload/{zingsnisid}")]
        [Consumes("multipart/form-data")]
        [Authorize]
        public async Task<ActionResult<PrisegtasFailas>> Upload(int zingsnisid, IFormFile file)
        {
            if (file == null || file.Length == 0) return BadRequest("No file uploaded.");

            var uploadsDir = Path.Combine(Directory.GetCurrentDirectory(), "uploads");
            if (!Directory.Exists(uploadsDir)) Directory.CreateDirectory(uploadsDir);

            var savedFileName = $"{Guid.NewGuid()}{Path.GetExtension(file.FileName)}";
            var filePath = Path.Combine(uploadsDir, savedFileName);

            await using (var stream = new FileStream(filePath, FileMode.Create))
            {
                await file.CopyToAsync(stream);
            }

            var model = new PrisegtasFailas
            {
                Id = Guid.NewGuid(),
                ZingsnisId = zingsnisid,
                FailoPav = file.FileName,
                Dydis = file.Length,
                Nuoroda = Path.Combine("uploads", savedFileName),
                SukurimoLaikas = DateTime.UtcNow
            };

            _db.PrisegtiFailai.Add(model);
            await _db.SaveChangesAsync();

            return CreatedAtAction(nameof(Get), new { id = model.Id }, model);
        }

        [HttpPost("uploadTemplate/{templateId}")]
        [Consumes("multipart/form-data")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<ActionResult<PrisegtasFailas>> UploadTemplateImage(int templateId, IFormFile file)
        {
            if (file == null || file.Length == 0) return BadRequest("No file uploaded.");
            if (!IsImageFileName(file.FileName)) return BadRequest("Only image files are allowed.");

            var templateExists = await _db.ZingsnisTemplate.AsNoTracking().AnyAsync(t => t.Id == templateId);
            if (!templateExists) return NotFound("Template not found.");

            var uploadsDir = Path.Combine(Directory.GetCurrentDirectory(), "uploads", "templates");
            if (!Directory.Exists(uploadsDir)) Directory.CreateDirectory(uploadsDir);

            var savedFileName = $"{Guid.NewGuid()}{Path.GetExtension(file.FileName)}";
            var filePath = Path.Combine(uploadsDir, savedFileName);

            await using (var stream = new FileStream(filePath, FileMode.Create))
            {
                await file.CopyToAsync(stream);
            }

            var model = new PrisegtasFailas
            {
                Id = Guid.NewGuid(),
                ZingsnisId = null,
                ZingsnisTemplateId = templateId,
                FailoPav = file.FileName,
                Dydis = file.Length,
                Nuoroda = Path.Combine("uploads", "templates", savedFileName),
                SukurimoLaikas = DateTime.UtcNow
            };

            _db.PrisegtiFailai.Add(model);
            await _db.SaveChangesAsync();

            return CreatedAtAction(nameof(Get), new { id = model.Id }, model);
        }

        [HttpPut("{id}")]
        [Authorize]
        public async Task<IActionResult> Update(Guid id, PrisegtasFailas model)
        {
            if (id != model.Id) return BadRequest();
            _db.Entry(model).State = EntityState.Modified;
            await _db.SaveChangesAsync();
            return NoContent();
        }

        [HttpDelete("{id}")]
        [Authorize]
        public async Task<IActionResult> Delete(Guid id)
        {
            var item = await _db.PrisegtiFailai.FindAsync(id);
            if (item == null) return NotFound();

            TryDeletePhysicalFile(item.Nuoroda);

            _db.PrisegtiFailai.Remove(item);
            await _db.SaveChangesAsync();
            return NoContent();
        }
    }
}
