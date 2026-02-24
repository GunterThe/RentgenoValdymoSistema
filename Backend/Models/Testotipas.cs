using NpgsqlTypes;

namespace Backend.Models
{
    public enum TestoTipas
    {
        [PgName("testas")]
        Testas,
        
        [PgName("isvezimas")]
        Isvezimas,
        
        [PgName("pakavimas")]
        Pakavimas
    }
}
