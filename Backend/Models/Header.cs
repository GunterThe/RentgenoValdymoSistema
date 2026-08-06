using System;
using System.Collections.Generic;
using System.Text.Json.Serialization;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Backend.Models
{
    [Table("header")]
    public class Header
    {
        [Key]
        [Column("id")]
        public int Id { get; set; }

        [Required]
        [Column("text")]
        public string Text { get; set; } = null!;

        [Required]
        [Column("row_id")]
        public int RowId { get; set; }

        [JsonIgnore]
        public Row? Row { get; set; }
    }
}