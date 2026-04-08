using System;
using System.Collections.Generic;
using System.Text.Json.Serialization;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Backend.Models
{
    [Table("zingsnis_template")]
    public class ZingsnisTemplate
    {
        [Key]
        [Column("id")]
        public int Id { get; set; }

        [Required]
        [Column("pavadinimas")]
        public string Pavadinimas { get; set; } = null!;

        [Required]
        [Column("aprasymas")]
        public string Aprasymas { get; set; } = null!;

        [Required]
        [Column("testas_id")]
        public int TestasId { get; set; }

        [Required]
        [Column("eile")]
        public int Eile { get; set; }
        
        [Column("komentaras_privalomas")]
        public bool KomentarasPrivalomas { get; set; } = false;

        [Column("nuotrauka_privaloma")]
        public bool NuotraukaPrivaloma { get; set; } = false;

        [JsonIgnore]
        public Testas? Testas { get; set; }
    }
}
