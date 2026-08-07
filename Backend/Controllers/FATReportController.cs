using System.Collections.Generic;
using System;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Threading.Tasks;
using Backend.Data;
using Backend.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore.Storage;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Npgsql;
using NpgsqlTypes;

namespace Backend.Controllers
{
    [ApiController]
    [Authorize]
    [Route("api/[controller]")]
    public class FATReportController : ControllerBase
    {
        private readonly AppDbContext _db;
        public FATReportController(AppDbContext db) => _db = db;

        [HttpGet]
        public async Task<ActionResult<IEnumerable<FATReport>>> GetAll() => await _db.FATReports.ToListAsync();

        [HttpGet("{id}")]
        public async Task<ActionResult<FATReport>> Get(int id)
        {
            var item = await _db.FATReports.FindAsync(id);
            if (item == null) return NotFound();
            return item;
        }

        [HttpPost]
        [Authorize(Policy = "AdminOnly")]
        public async Task<ActionResult<FATReport>> Create(FATReport fatReport)
        {
            _db.FATReports.Add(fatReport);
            await _db.SaveChangesAsync();
            return CreatedAtAction(nameof(Get), new { id = fatReport.Id }, fatReport);
        }

        public class CopyFATRequest
        {
            public string? NewFATReportName { get; set; }
        }

        [HttpPost("copy/{id}")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<ActionResult<FATReport>> Copy(int id, [FromBody] CopyFATRequest? req)
        {
            var original = await _db.FATReports.AsNoTracking().FirstOrDefaultAsync(t => t.Id == id);
            if (original == null) return NotFound();
            var templates = await _db.ReportTemplates
                .Where(z => z.FATReportId == id)
                .OrderBy(z => z.Order)
                .AsNoTracking()
                .ToListAsync();

            var newFATReportName = !string.IsNullOrWhiteSpace(req?.NewFATReportName)
                ? req!.NewFATReportName!.Trim()
                : original.Text + " (Kopija)";

            await using var tx = await _db.Database.BeginTransactionAsync();
            try
            {
                var newFAT = new FATReport
                {
                    Text = newFATReportName
                };
                _db.FATReports.Add(newFAT);
                await _db.SaveChangesAsync();

                var newFATId = newFAT.Id;

                foreach (var t in templates)
                {
                    var newTemplate = new ReportTemplate
                    {
                        Text = t.Text,
                        FATReportId = newFATId,
                        Order = t.Order
                    };
                    _db.ReportTemplates.Add(newTemplate);
                }

                await _db.SaveChangesAsync();
                await tx.CommitAsync();

                var created = await _db.FATReports.AsNoTracking().FirstAsync(f => f.Id == newFATId);
                return CreatedAtAction(nameof(Get), new { id = created.Id }, created);
            }
            catch
            {
                await tx.RollbackAsync();
                throw;
            }
        }

        [HttpPut("{id}")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> Update(int id, FATReport fatReport)
        {
            if (id != fatReport.Id) return BadRequest();
            var exists = await _db.FATReports.AsNoTracking().AnyAsync(t => t.Id == id);
            if (!exists) return NotFound();

            _db.Entry(fatReport).State = EntityState.Modified;
            await _db.SaveChangesAsync();
            return NoContent();
        }

        [HttpDelete("{id}")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> Delete(int id)
        {
            var item = await _db.FATReports.FindAsync(id);
            if (item == null) return NotFound();
            _db.FATReports.Remove(item);
            await _db.SaveChangesAsync();
            return NoContent();
        }
    }
}