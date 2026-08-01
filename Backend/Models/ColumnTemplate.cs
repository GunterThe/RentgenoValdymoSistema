using System;
using System.Collections.Generic;
using System.Text.Json.Serialization;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Backend.Models
{
    [Table("column_template")]
    public class ColumnTemplate
    {
        [Key]
        [Column("id")]
        public int Id { get; set; }

        [Required]
        [Column("description")]
        public string Description { get; set; } = null!;
        [Required]
        [Column("row_id")]
        public int RowId { get; set; }

        [Required]
        [Column("order")]
        public int Order { get; set; }

        [Column("header_id")]
        public int HeaderId { get; set; }
        
        [Column("is_array")]
        public bool IsArray { get; set; } = false;

        [JsonIgnore]
        public Row? Row { get; set; }
        [JsonIgnore]
        public Header? Header { get; set; }
    }
}
