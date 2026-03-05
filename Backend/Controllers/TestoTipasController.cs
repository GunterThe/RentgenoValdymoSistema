using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using Backend.Models;
using Microsoft.AspNetCore.Mvc;
using NpgsqlTypes;
using Microsoft.AspNetCore.Authorization;

namespace Backend.Controllers
{
    [ApiController]
    [Authorize]
    [Route("api/[controller]")]
    public class TestoTipasController : ControllerBase
    {
        public record TestoTipasItem(string Name, string PgName, int Value);

        [HttpGet]
        public ActionResult<IEnumerable<TestoTipasItem>> GetAll()
        {
            var type = typeof(TestoTipas);
            var values = Enum.GetValues<TestoTipas>();

            var items = values
                .Select(v =>
                {
                    var member = type.GetMember(v.ToString()).FirstOrDefault();
                    var pgName = member?.GetCustomAttribute<PgNameAttribute>()?.PgName ?? v.ToString();
                    return new TestoTipasItem(v.ToString(), pgName, (int)v);
                })
                .ToList();

            return items;
        }
    }
}
