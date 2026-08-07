using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace Backend.Models
{
    [Table("fatreport_irasas")]
    public class FATReportIrasas
    {
        [Key]
        [Column("id")]
        public int Id { get; set; }
        
        [Column("fatreport_id")]
        public int FATReportId { get; set; }

        [Column("irasasid")]
        public int IrasasId { get; set; }

        [Column("order")]
        public int Order { get; set; }

        [ForeignKey(nameof(FATReportId))]
        [JsonIgnore]
        public FATReport? FATReport { get; set; }

        [ForeignKey(nameof(IrasasId))]
        [JsonIgnore]
        public Irasas? Irasas { get; set; }
    }
}