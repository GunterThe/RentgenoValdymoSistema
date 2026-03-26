using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace Backend.Models
{
    [Table("sablonas")]
    public class Sablonas
    {
        [Key]
        [Column("id")]
        public int Id { get; set; }

        [Required]
        [Column("pavadinimas")]
        public string Pavadinimas { get; set; } = null!;

        [JsonIgnore]
        public ICollection<SablonasTestas> Testai { get; set; } = new List<SablonasTestas>();
    }
}
