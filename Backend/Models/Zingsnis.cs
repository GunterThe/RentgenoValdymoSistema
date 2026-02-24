using System;
using System.Collections.Generic;
using System.Text.Json.Serialization;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Backend.Models
{
    [Table("zingsnis")]
    public class Zingsnis
    {
        [Key]
        [Column("id")]
        public int Id { get; set; }

        [Required]
        [Column("tekstas")]
        public string Tekstas { get; set; } = null!;

        [Required]
        [Column("komentaras")]
        public string Komentaras { get; set; } = null!;

        [Required]
        [Column("pabaigtas")]
        public bool Pabaigtas { get; set; }

        [Required]
        [Column("testas_id")]
        public int TestasId { get; set; }

        [JsonIgnore]
        public Testas Testas { get; set; } = null!;
    }
}
