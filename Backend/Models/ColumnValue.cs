using System;
using System.Collections.Generic;
using System.Text.Json.Serialization;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Backend.Models
{
    [Table("column_value")]
    public class ColumnValue
    {
        [Key]
        [Column("id")]
        public int Id { get; set; }

        [Column("single_value")]
        public decimal? SingleValue { get; set; } = null;
        
        [Column("array_value")]
        public decimal[]? ArrayValue { get; set; } = null;

        [Column("completed_at")]
        public DateTime? CompletedAt { get; set; }

        [Required]
        [Column("row_irasas_id")]
        public int RowIrasasId { get; set; }

        [Required]
        [Column("column_template_id")]
        public int ColumnTemplateId { get; set; }

        [Column("completed_by_user_id")]
        public Guid? CompletedByUserId { get; set; }

        [JsonIgnore]
        public RowIrasas? RowIrasas { get; set; }

        [JsonIgnore]
        public ColumnTemplate? ColumnTemplate { get; set; }

        [JsonIgnore]
        public Naudotojas? CompletedByUser { get; set; }

        [NotMapped]
        public bool Pabaigtas { get; set; }

    }
}
