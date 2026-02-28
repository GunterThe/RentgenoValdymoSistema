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
        [Column("komentaras")]
        public string Komentaras { get; set; } = null!;

        [Column("completed_at")]
        public DateTime? CompletedAt { get; set; }

        [Required]
        [Column("irasas_testas_id")]
        public int TestasIrasasId { get; set; }

        [Required]
        [Column("zingsnis_template_id")]
        public int ZingsnisTemplateId { get; set; }

        [Required]
        [Column("completed_by_user_id")]
        public Guid CompletedByUserId { get; set; }

        [JsonIgnore]
        public TestasIrasas? TestasIrasas { get; set; }

        [JsonIgnore]
        public ZingsnisTemplate? ZingsnisTemplate { get; set; }

        [JsonIgnore]
        public Naudotojas? CompletedByUser { get; set; }

        [NotMapped]
        public bool Pabaigtas { get; set; }

    }
}
