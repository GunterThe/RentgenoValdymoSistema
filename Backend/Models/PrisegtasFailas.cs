using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace Backend.Models
{
    [Table("prisegtasfailas")]
    public class PrisegtasFailas
    {
        [Key]
        [Column("id")]
        public Guid Id { get; set; }

        [Column("irasasid")]
        public int? Irasasid { get; set; }

        [Column("failopav")]
        public string? FailoPav { get; set; }

        [Column("dydis")]
        public long? Dydis { get; set; }

        [Column("nuoroda")]
        public string? Nuoroda { get; set; }

        [Column("sukurimolaikas")]
        public DateTime? SukurimoLaikas { get; set; }

        [JsonIgnore]
        public Irasas? Irasas { get; set; }
    }
}
