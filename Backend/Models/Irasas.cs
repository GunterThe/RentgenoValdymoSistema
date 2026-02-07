using System;
using System.Collections.Generic;
using System.Text.Json.Serialization;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Backend.Models
{
    [Table("irasas")]
    public class Irasas
    {
        [Key]
        [Column("id")]
        public int Id { get; set; }

        [Required]
        [Column("id_dokumento")]
        public string IdDokumento { get; set; } = null!;

        [Required]
        [Column("pavadinimas")]
        public string Pavadinimas { get; set; } = null!;

        [Required]
        [Column("pradzia")]
        public DateTime Pradzia { get; set; }

        [Required]
        [Column("pabaiga")]
        public DateTime Pabaiga { get; set; }

        [JsonIgnore]
        public ICollection<TestasIrasas> Testai { get; set; } = new List<TestasIrasas>();
    }
}
