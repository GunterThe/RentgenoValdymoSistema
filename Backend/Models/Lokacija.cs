using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace Backend.Models
{
    [Table("lokacija")]
    public class Lokacija
    {
        [Key]
        [Column("id")]
        public int Id { get; set; }

        [Required]
        [Column("pavadinimas")]
        public string Pavadinimas { get; set; } = null!;
    }
}