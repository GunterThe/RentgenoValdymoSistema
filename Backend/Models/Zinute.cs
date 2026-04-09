using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace Backend.Models
{
    [Table("zinute")]
    public class Zinute
    {
        [Key]
        [Column("id")]
        public int Id { get; set; }

        [Required]
        [Column("tekstas")]
        public string Tekstas { get; set; } = null!;

        [JsonIgnore]
        public ICollection<NaudotojasZinute> Naudotojai { get; set; } = new List<NaudotojasZinute>();
    }
}