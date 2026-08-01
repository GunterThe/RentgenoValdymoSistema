using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace Backend.Models
{
    [Table("row_irasas")]
    public class RowIrasas
    {
        [Key]
        [Column("id")]
        public int Id { get; set; }
        
        [Column("row_id")]
        public int RowId { get; set; }

        [Column("irasas_id")]
        public int IrasasId { get; set; }

        [Column("order")]
        public int Order { get; set; }

        [ForeignKey(nameof(RowId))]
        [JsonIgnore]
        public Row? Row { get; set; }

        [ForeignKey(nameof(IrasasId))]
        [JsonIgnore]
        public Irasas? Irasas { get; set; }
    }
}