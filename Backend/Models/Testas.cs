using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace Backend.Models
{
    [Table("testas")]
    public class Testas
    {
        [Key]
        [Column("id")]
        public int Id { get; set; }

        [Required]
        [Column("testotekstas")]
        public string Testotekstas { get; set; } = null!;

        [Column("tipas")]
        public TestoTipas? Tipas { get; set; }

        [JsonIgnore]
        public ICollection<TestasIrasas> Irasai { get; set; } = new List<TestasIrasas>();
    }
}
