using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace Backend.Models
{
    [Table("sablonas_testas")]
    public class SablonasTestas
    {
        
        [Column("sablonasid")]
        public int Sablonasid { get; set; }

        [Column("testasid")]
        public int Testasid { get; set; }

        [ForeignKey(nameof(Testasid))]
        [JsonIgnore]
        public Testas? Testas { get; set; }

        [ForeignKey(nameof(Sablonasid))]
        [JsonIgnore]
        public Sablonas? Sablonas { get; set; }
    }
}