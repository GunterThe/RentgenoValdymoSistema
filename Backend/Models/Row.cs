using System;
using System.Collections.Generic;
using System.Text.Json.Serialization;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Backend.Models
{
    [Table("row")]
    public class Row
    {
        [Key]
        [Column("id")]
        public int Id { get; set; }

        [Required]
        [Column("description")]
        public string Description { get; set; } = null!;

        [Column("control_methods")]
        public string? ControlMethods { get; set; }

        [JsonIgnore]
        public ICollection<RowIrasas> Irasas { get; set; } = new List<RowIrasas>();

        [JsonIgnore]
        public ICollection<FATRow> FATRows { get; set; } = new List<FATRow>();
    }
}