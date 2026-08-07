using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace Backend.Models
{
    [Table("fatreport")]
    public class FATReport
    {
        [Key]
        [Column("id")]
        public int Id { get; set; }

        [Required]
        [Column("text")]
        public string Text { get; set; } = null!;

        [JsonIgnore]
        public ICollection<TestasIrasas> Irasai { get; set; } = new List<TestasIrasas>();
    }
}
