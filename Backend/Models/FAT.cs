using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace Backend.Models
{
    [Table("fat")]
    public class FAT
    {
        [Key]
        [Column("id")]
        public int Id { get; set; }

        [Required]
        [Column("title")]
        public string Title { get; set; } = null!;

        [JsonIgnore]
        public ICollection<FATRow> Rows { get; set; } = new List<FATRow>();
    }
}