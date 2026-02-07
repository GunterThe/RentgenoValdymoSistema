using System.ComponentModel.DataAnnotations.Schema;

namespace Backend.Models
{
    [Table("testasirasas")]
    public class TestasIrasas
    {
        [Column("testasid")]
        public int Testasid { get; set; }

        [Column("irasasid")]
        public int Irasasid { get; set; }

        [ForeignKey("Testasid")]
        public Testas? Testas { get; set; }

        [ForeignKey("Irasasid")]
        public Irasas? Irasas { get; set; }
    }
}
