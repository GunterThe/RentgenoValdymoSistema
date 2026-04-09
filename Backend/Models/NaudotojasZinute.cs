using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;
using System;

namespace Backend.Models
{
    [Table("naudotojas_zinute")]
    public class NaudotojasZinute
    {
        
        [Column("naudotojas_id")]
        public Guid Naudotojasid { get; set; }

        [Column("zinute_id")]
        public int Zinuteid { get; set; }

        [Column("perskaityta")]
        public bool Perskaityta { get; set; } = false;

        [ForeignKey(nameof(Zinuteid))]
        [JsonIgnore]
        public Zinute? Zinute { get; set; }

        [ForeignKey(nameof(Naudotojasid))]
        [JsonIgnore]
        public Naudotojas? Naudotojas { get; set; }
    }
}