using System;
using System.Collections.Generic;
using System.Text.Json.Serialization;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Backend.Models
{
    [Table("report_template")]
    public class ReportTemplate
    {
        [Key]
        [Column("id")]
        public int Id { get; set; }

        [Required]
        [Column("text")]
        public string Text { get; set; } = null!;

        [Required]
        [Column("fatreport_id")]
        public int FATReportId { get; set; }

        [Required]
        [Column("order")]
        public int Order { get; set; }
        
        [JsonIgnore]
        public FATReport? FATReport { get; set; }
    }
}
