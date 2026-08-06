using System;
using System.Collections.Generic;
using System.Text.Json.Serialization;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Backend.Models
{
    [Table("row_value")]
    public class RowValue
    {
        [Key]
        [Column("id")]
        public int Id { get; set; }

        [Column("value")]
        public string? Value { get; set; } = null;
        
        [Column("completed_at")]
        public DateTime? CompletedAt { get; set; }

        [Column("completed_by_user_id")]
        public Guid? CompletedByUserId { get; set; }

        [Column("row_id")]
        public int RowId { get; set; }

        [Column("row_irasas_id")]
        public int RowIrasasId { get; set; }

        [JsonIgnore]
        [ForeignKey(nameof(RowId))]
        public Row? Row { get; set; }

        [JsonIgnore]
        [ForeignKey(nameof(RowIrasasId))]
        public RowIrasas? RowIrasas { get; set; }

    }
}
