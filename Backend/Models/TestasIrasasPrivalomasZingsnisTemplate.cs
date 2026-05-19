using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace Backend.Models
{
    [Table("testasirasas_privalomas_zingsnis_template")]
    public class TestasIrasasPrivalomasZingsnisTemplate
    {
        [Column("testasirasas_id")]
        public int TestasIrasasId { get; set; }

        [Column("zingsnis_template_id")]
        public int ZingsnisTemplateId { get; set; }

        [JsonIgnore]
        public TestasIrasas? TestasIrasas { get; set; }

        [JsonIgnore]
        public ZingsnisTemplate? ZingsnisTemplate { get; set; }
    }
}
