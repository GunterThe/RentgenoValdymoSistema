using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Backend.Models
{
    [Table("chat_zinute")]
    public class ChatZinute
    {
        [Key]
        [Column("id")]
        public int Id { get; set; }

        [Column("siuntetojo_id")]
        public string SiuntejoId { get; set; } = string.Empty;

        [Column("siuntetojo_vardas")]
        public string SiuntejoVardas { get; set; } = string.Empty;

        [Column("gavetojo_id")]
        public string GavetojoId { get; set; } = string.Empty;

        [Column("gavetojo_vardas")]
        public string GavetojoVardas { get; set; } = string.Empty;

        [Required]
        [Column("tekstas")]
        public string Tekstas { get; set; } = string.Empty;

        [Column("siusto_laikas")]
        public DateTime SiustoLaikas { get; set; } = DateTime.UtcNow;
    }
}
