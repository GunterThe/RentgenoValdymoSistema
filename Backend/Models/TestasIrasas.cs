using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace Backend.Models
{
    [Table("testasirasas")]
    public class TestasIrasas
    {
        [Column("testasid")]
        public int Testasid { get; set; }

        [Column("irasasid")]
        public int Irasasid { get; set; }

        [ForeignKey(nameof(Testasid))]
        [JsonIgnore]
        public Testas? Testas { get; set; }

        [ForeignKey(nameof(Irasasid))]
        [JsonIgnore]
        public Irasas? Irasas { get; set; }
    }
}
