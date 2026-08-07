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
    public class ReportValueController : ControllerBase
    {
        private readonly AppDbContext _db;
        public ReportValueController(AppDbContext db) => _db = db;

        private sealed record TemplateLite(int Id, int Eile, int TestasId);

        [HttpGet]
        public async Task<ActionResult<IEnumerable<ReportValue>>> GetAll() =>
            await _db.ReportValues.ToListAsync();

        [HttpGet("{id}")]
        public async Task<ActionResult<ReportValue>> Get(int id)
        {
            var item = await _db.ReportValues.FindAsync(id);
            if (item == null) return NotFound();
            return item;
        }
        [HttpGet("getByEverything/{fATReportIrasasId}/{reportTemplateId}")]
        public async Task<ActionResult<ReportValue>> GetByEverything(int fATReportIrasasId, int reportTemplateId)
        {
            var item = await _db.ReportValues.FirstOrDefaultAsync(z => z.FATReportIrasasId == fATReportIrasasId && z.ReportTemplateId == reportTemplateId);
            if (item == null) return NotFound();
            return item;
        }

        [HttpPost]
        public async Task<ActionResult<ReportValue>> Create(ReportValue reportValue)
        {
            _db.ReportValues.Add(reportValue);
            await _db.SaveChangesAsync();

            return CreatedAtAction(nameof(Get), new { id = reportValue.Id }, reportValue);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, ReportValue reportValue)
        {
            ReportValue? temp = await _db.ReportValues.AsNoTracking().FirstOrDefaultAsync(z => z.Id == id);
            if (temp == null) return NotFound();
            bool isAdmin = User.HasClaim("admin", bool.TrueString);
            if (id != reportValue.Id) return BadRequest();

            if((reportValue.Value == null || reportValue.Value.Length == 0) && !isAdmin && (temp.Value != null || temp.Value.Length > 0))
            {
                return BadRequest("Tik adminas gali ištrinti reikšmę");
            }
            else if((reportValue.Value == null || reportValue.Value.Length == 0) && isAdmin)
            {
                reportValue.Value = "";
            }

            _db.Entry(reportValue).State = EntityState.Modified;
            await _db.SaveChangesAsync();
            return NoContent();
        }

        [HttpDelete("{id}")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> Delete(int id)
        {
            var item = await _db.ReportValues.FindAsync(id);
            if (item == null) return NotFound();
            _db.ReportValues.Remove(item);
            await _db.SaveChangesAsync();

            return NoContent();
        }
    }
}