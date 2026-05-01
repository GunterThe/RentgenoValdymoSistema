using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace Backend.Models
{
    [Table("naudotojas")]
    public class Naudotojas
    {
        [Key]
        [Column("id")]
        public Guid Id { get; set; } = Guid.NewGuid();

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

        [Required]
        [Column("prisijungimoid")]
        public string PrisijungimoId { get; set; } = null!;

        [Column("super_adminas")]
        public bool SuperAdminas { get; set; } = false;

        [Required]
        [Column("must_change_password")]
        public bool MustChangePassword { get; set; } = false;

        [JsonIgnore]
        public List<RefreshToken> RefreshToken { get; set; } = new List<RefreshToken>();
        [JsonIgnore]
        public ICollection<NaudotojasZinute> Zinutes { get; set; } = new List<NaudotojasZinute>();
    }
}
