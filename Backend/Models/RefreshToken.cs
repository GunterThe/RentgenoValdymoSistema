using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;


namespace Backend.Models
{
    [Table("refreshtoken")]
    public class RefreshToken
    {
        [Key]
        [Column("id")]
        public Guid Id { get; set; }

        [Required]
        [Column("token")]
        public string Token { get; set; } = string.Empty;

        [Required]
        [Column("expires")]
        public DateTime Expires { get; set; }
        [Column("revoked")]
        public DateTime? Revoked { get; set; }

        [Required]
        [Column("naudotojasid")]
        public Guid NaudotojasId { get; set; }

        [JsonIgnore]
        public Naudotojas? Naudotojas { get; set; }

        public bool IsActive => Revoked == null && DateTime.UtcNow < Expires;
    }
}