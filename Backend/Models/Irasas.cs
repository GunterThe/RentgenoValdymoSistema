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

        [Column("pradzia")]
        public DateTime Pradzia { get; set; }

        [Column("pabaiga")]
        public DateTime? Pabaiga { get; set; }
        
        [Column("statusas")]
        public string Statusas { get; set; } = null!;

        [JsonIgnore]
        public ICollection<TestasIrasas> Testai { get; set; } = new List<TestasIrasas>();
    }
}
