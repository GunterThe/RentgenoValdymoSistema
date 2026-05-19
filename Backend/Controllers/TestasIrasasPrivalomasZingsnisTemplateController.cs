using System.Collections.Generic;
using System.Linq;
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
    public class TestasIrasasPrivalomasZingsnisTemplateController : ControllerBase
    {
        private readonly AppDbContext _db;
        public TestasIrasasPrivalomasZingsnisTemplateController(AppDbContext db) => _db = db;

        [HttpGet]
        public async Task<ActionResult<IEnumerable<TestasIrasasPrivalomasZingsnisTemplate>>> GetAll()
        {
            return await _db.TestasIrasasPrivalomiZingsniai
                .AsNoTracking()
                .OrderBy(x => x.TestasIrasasId)
                .ThenBy(x => x.ZingsnisTemplateId)
                .ToListAsync();
        }

        [HttpGet("{testasIrasasId:int}")]
        public async Task<ActionResult<IEnumerable<TestasIrasasPrivalomasZingsnisTemplate>>> GetByTestasIrasasId(int testasIrasasId)
        {
            return await _db.TestasIrasasPrivalomiZingsniai
                .AsNoTracking()
                .Where(x => x.TestasIrasasId == testasIrasasId)
                .OrderBy(x => x.ZingsnisTemplateId)
                .ToListAsync();
        }

        public sealed class SetRequest
        {
            public List<int> ZingsnisTemplateIds { get; set; } = new();
        }

        [HttpPut("{testasIrasasId:int}")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> SetForTestasIrasas(int testasIrasasId, SetRequest request)
        {
            var link = await _db.TestasIrasai.AsNoTracking().FirstOrDefaultAsync(x => x.Id == testasIrasasId);
            if (link == null) return NotFound(new { message = "TestasIrasas not found" });

            var ids = (request?.ZingsnisTemplateIds ?? new List<int>())
                .Where(x => x > 0)
                .Distinct()
                .ToList();

            if (ids.Count > 0)
            {
                var allowed = await _db.ZingsnisTemplate
                    .AsNoTracking()
                    .Where(t => t.TestasId == link.Testasid && ids.Contains(t.Id))
                    .Select(t => t.Id)
                    .ToListAsync();

                if (allowed.Count != ids.Count)
                    return BadRequest(new { message = "One or more ZingsnisTemplateIds do not belong to this testas." });
            }

            var existing = await _db.TestasIrasasPrivalomiZingsniai
                .Where(x => x.TestasIrasasId == testasIrasasId)
                .ToListAsync();

            _db.TestasIrasasPrivalomiZingsniai.RemoveRange(existing);

            foreach (var tplId in ids)
            {
                _db.TestasIrasasPrivalomiZingsniai.Add(new TestasIrasasPrivalomasZingsnisTemplate
                {
                    TestasIrasasId = testasIrasasId,
                    ZingsnisTemplateId = tplId,
                });
            }

            await _db.SaveChangesAsync();
            return NoContent();
        }
    }
}
