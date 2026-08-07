using System;
using System.Collections.Generic;
using System.Text.Json.Serialization;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Backend.Models
{
    [Table("report_value")]
    public class ReportValue
    {
        [Key]
        [Column("id")]
        public int Id { get; set; }

        [Required]
        [Column("value")]
        public string Value { get; set; } = null!;

        [Required]
        [Column("fatreport_irasasid")]
        public int FATReportIrasasId { get; set; }

        [Required]
        [Column("report_template_id")]
        public int ReportTemplateId { get; set; }

        [JsonIgnore]
        public FATReportIrasas? FATReportIrasas { get; set; }

        [JsonIgnore]
        public ReportTemplate? ReportTemplate { get; set; }

    }
}