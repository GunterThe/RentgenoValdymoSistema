using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Backend.Models
{
    [Table("naudotojas")]
    public class Naudotojas
    {
        [Key]
        [Column("id")]
        public Guid Id { get; set; }

        [Required]
        [MaxLength(30)]
        [Column("vardas")]
        public string Vardas { get; set; } = null!;

        [Required]
        [MaxLength(30)]
        [Column("pavarde")]
        public string Pavarde { get; set; } = null!;

        [Required]
        [Column("gimimo_data")]
        public DateTime GimimoData { get; set; }

        [Required]
        [Column("adminas")]
        public bool Adminas { get; set; }

        [Required]
        [MaxLength(200)]
        [Column("password_hash")]
        public string PasswordHash { get; set; } = null!;
    }
}
