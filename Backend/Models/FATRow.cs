using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace Backend.Models
{
    [Table("fat_row")]
    public class FATRow
    {
        
        [Column("fatid")]
        public int Fatid { get; set; }

        [Column("rowid")]
        public int Rowid { get; set; }

        [Column("order")]
        public int Order { get; set; }

        [ForeignKey(nameof(Rowid))]
        [JsonIgnore]
        public Row? Row { get; set; }

        [ForeignKey(nameof(Fatid))]
        [JsonIgnore]
        public FAT? FAT { get; set; }
    }
}