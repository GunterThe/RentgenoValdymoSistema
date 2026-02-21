using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authorization;
using System.IdentityModel.Tokens.Jwt;
using Backend.Data;

namespace Backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly AppDbContext _db;
        private readonly ITokenService _tokenService;

        public AuthController(AppDbContext db, ITokenService tokenService)
        {
            _db = db;
            _tokenService = tokenService;
        }

        public record RegisterRequest(string Vardas, string Pavarde, DateTime Gimimo_data, string PrisijungimoId, string Password);
        public record AuthResponse(string AccessToken, string RefreshToken);
        public record LoginRequest(string PrisijungimoId, string Password);
        public record RefreshRequest(string RefreshToken);

        [HttpPost("login")]
        [AllowAnonymous]
        public async Task<ActionResult<AuthResponse>> Login(LoginRequest req)
        {
            // No need to load RefreshToken collection here; avoiding it prevents provider type mismatches
            var user = await _db.Naudotojai.FirstOrDefaultAsync(u => u.PrisijungimoId == req.PrisijungimoId);
            if (user == null || !BCrypt.Net.BCrypt.Verify(req.Password, user.PasswordHash))
            {
                return Unauthorized(new { message = "Invalid credentials" });
            }
            var refresh = _tokenService.CreateRefreshToken(user);
            // Add the refresh token directly; NaudotojasId is set in the token factory
            _db.RefreshTokens.Add(refresh);
            await _db.SaveChangesAsync();
            var access = _tokenService.CreateAccessToken(user);
            return Ok(new AuthResponse(access, refresh.Token));
        }

        [HttpPost("refresh")]
        [AllowAnonymous]
        public async Task<ActionResult<AuthResponse>> Refresh(RefreshRequest req)
        {
            if (string.IsNullOrWhiteSpace(req.RefreshToken))
            {
                return Unauthorized(new { message = "Invalid refresh token" });
            }

            var tokenEntity = await _db.RefreshTokens
                .FirstOrDefaultAsync(r => r.Token == req.RefreshToken);
            if (tokenEntity == null || !tokenEntity.IsActive)
            {
                return Unauthorized(new { message = "Invalid refresh token" });
            }
            // Revoke old
            tokenEntity.Revoked = DateTime.UtcNow;

            var user = await _db.Naudotojai.FirstOrDefaultAsync(u => u.Id == tokenEntity.NaudotojasId);
            if (user == null)
            {
                return Unauthorized(new { message = "Invalid refresh token" });
            }

            var newRefresh = _tokenService.CreateRefreshToken(user);
            _db.RefreshTokens.Add(newRefresh);
            await _db.SaveChangesAsync();
            var access = _tokenService.CreateAccessToken(user);
            return Ok(new AuthResponse(access, newRefresh.Token));
        }

        [HttpPost("revoke")]
        [Authorize]
        public async Task<IActionResult> Revoke(RefreshRequest req)
        {
            var tokenEntity = await _db.RefreshTokens.FirstOrDefaultAsync(r => r.Token == req.RefreshToken);
            if (tokenEntity == null || !tokenEntity.IsActive) return NotFound();
            tokenEntity.Revoked = DateTime.UtcNow;
            await _db.SaveChangesAsync();
            return NoContent();
        }

        public record GeneratedRefreshToken(string Token, DateTime ExpiresOn);
        
        private GeneratedRefreshToken GenerateRefreshToken()
        {
            var randomNumber = new byte[64];
            using (var rng = System.Security.Cryptography.RandomNumberGenerator.Create())
            {
                rng.GetBytes(randomNumber);
            }

            var refreshToken = new GeneratedRefreshToken(
                Token: Convert.ToBase64String(randomNumber),
                ExpiresOn: DateTime.UtcNow.AddDays(7)
            );

            return refreshToken;
        }


        [HttpGet("token")]
        [Authorize]
        [Authorize(Policy = "AdminOnly")]
        public ActionResult<object> CurrentToken()
        {
            var authHeader = Request.Headers["Authorization"].FirstOrDefault();
            if (string.IsNullOrWhiteSpace(authHeader) || !authHeader.StartsWith("Bearer "))
            {
                return BadRequest(new { message = "No bearer token provided" });
            }

            var token = authHeader.Substring("Bearer ".Length).Trim();
            JwtSecurityToken? jwt = null;
            try
            {
                var handler = new JwtSecurityTokenHandler();
                jwt = handler.ReadJwtToken(token);
            }
            catch
            {
                return BadRequest(new { message = "Invalid JWT format" });
            }

            var claims = jwt.Claims.Select(c => new { c.Type, c.Value });
            return Ok(new { token, claims });
        }

        
    }
}
