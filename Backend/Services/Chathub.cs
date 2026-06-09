using System;
using System.IdentityModel.Tokens.Jwt;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;
using System.Collections.Concurrent;
using System.Collections.Generic;
using Backend.Data;
using Backend.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;

namespace Backend.Services
{
    [Authorize]
    public class Chathub : Hub
    {
        private readonly AppDbContext _db;
        // map userId -> set of connectionIds
        private static readonly ConcurrentDictionary<string, HashSet<string>> _connections
            = new(StringComparer.OrdinalIgnoreCase);

        public Chathub(AppDbContext db) => _db = db;

        private string GetSenderId() =>
            Context.User?.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? Context.User?.FindFirstValue(JwtRegisteredClaimNames.Sub)
            ?? Context.User?.FindFirstValue("sub")
            ?? string.Empty;

        private string GetSenderName()
        {
            var vardas = (Context.User?.FindFirstValue("vardas") ?? string.Empty).Trim();
            var pavarde = (Context.User?.FindFirstValue("pavarde") ?? string.Empty).Trim();
            if (vardas.Length == 0 && pavarde.Length == 0)
                return (Context.User?.FindFirstValue("email") ?? "Nežinomas").Trim();
            return $"{vardas} {pavarde}".Trim();
        }

        public async Task SendMessage(string toUserId, string tekstas)
        {
            var text = (tekstas ?? string.Empty).Trim();
            var to = (toUserId ?? string.Empty).Trim();
            if (string.IsNullOrEmpty(text) || string.IsNullOrEmpty(to)) return;

            var msg = new ChatZinute
            {
                SiuntejoId = GetSenderId(),
                SiuntejoVardas = GetSenderName(),
                GavetojoId = to,
                GavetojoVardas = string.Empty,
                Tekstas = text,
                SiustoLaikas = DateTime.UtcNow,
            };
            _db.ChatZinutes.Add(msg);
            await _db.SaveChangesAsync();

            var payload = new
            {
                msg.Id,
                msg.SiuntejoId,
                msg.SiuntejoVardas,
                msg.GavetojoId,
                msg.GavetojoVardas,
                msg.Tekstas,
                SiustoLaikas = msg.SiustoLaikas.ToString("o"),
            };

            // Send to receiver and caller
            await Clients.User(to).SendAsync("ReceiveMessage", payload);
            await Clients.Caller.SendAsync("ReceiveMessage", payload);
        }

        public override async Task OnConnectedAsync()
        {
            var user = GetSenderId();
            if (!string.IsNullOrEmpty(user))
            {
                var connId = Context.ConnectionId;
                var set = _connections.GetOrAdd(user, _ => new HashSet<string>());
                lock (set)
                {
                    set.Add(connId);
                }

                // notify others
                await Clients.Others.SendAsync("UserOnline", user);

                // send current online list to caller
                var online = _connections.Keys.ToList();
                await Clients.Caller.SendAsync("OnlineUsers", online);
            }

            await base.OnConnectedAsync();
        }

        public override async Task OnDisconnectedAsync(Exception? exception)
        {
            var user = GetSenderId();
            if (!string.IsNullOrEmpty(user))
            {
                if (_connections.TryGetValue(user, out var set))
                {
                    lock (set)
                    {
                        set.Remove(Context.ConnectionId);
                        if (set.Count == 0)
                        {
                            _connections.TryRemove(user, out _);
                        }
                    }

                    // if user now has no connections, announce offline
                    if (!_connections.ContainsKey(user))
                    {
                        await Clients.Others.SendAsync("UserOffline", user);
                    }
                }
            }

            await base.OnDisconnectedAsync(exception);
        }

        public async Task Typing(string toUserId)
        {
            var from = GetSenderId();
            var to = (toUserId ?? string.Empty).Trim();
            if (string.IsNullOrEmpty(from) || string.IsNullOrEmpty(to)) return;
            await Clients.User(to).SendAsync("UserTyping", from);
        }

        public async Task StopTyping(string toUserId)
        {
            var from = GetSenderId();
            var to = (toUserId ?? string.Empty).Trim();
            if (string.IsNullOrEmpty(from) || string.IsNullOrEmpty(to)) return;
            await Clients.User(to).SendAsync("UserStoppedTyping", from);
        }

        public async Task GetHistory(string otherUserId, int count = 50)
        {
            var take = Math.Clamp(count, 1, 200);
            var me = GetSenderId();
            var other = (otherUserId ?? string.Empty).Trim();
            if (string.IsNullOrEmpty(other))
            {
                await Clients.Caller.SendAsync("ChatHistory", Array.Empty<object>());
                return;
            }

            var messages = await _db.ChatZinutes
                .Where(m => (m.SiuntejoId == me && m.GavetojoId == other) || (m.SiuntejoId == other && m.GavetojoId == me))
                .OrderByDescending(m => m.SiustoLaikas)
                .Take(take)
                .OrderBy(m => m.SiustoLaikas)
                .ToListAsync();

            await Clients.Caller.SendAsync("ChatHistory", messages.Select(m => new
            {
                m.Id,
                m.SiuntejoId,
                m.SiuntejoVardas,
                m.GavetojoId,
                m.GavetojoVardas,
                m.Tekstas,
                SiustoLaikas = m.SiustoLaikas.ToString("o"),
            }));
        }

        public async Task GetConversations(int limit = 50)
        {
            var take = Math.Clamp(limit, 1, 200);
            var me = GetSenderId();

            // fetch recent messages involving me
            var recent = await _db.ChatZinutes
                .Where(m => m.SiuntejoId == me || m.GavetojoId == me)
                .OrderByDescending(m => m.SiustoLaikas)
                .Take(200)
                .ToListAsync();

            var grouped = recent
                .GroupBy(m => m.SiuntejoId == me ? m.GavetojoId : m.SiuntejoId)
                .Select(g => g.First())
                .OrderByDescending(m => m.SiustoLaikas)
                .Take(take)
                .ToList();

            var results = new List<object>();
            foreach (var m in grouped)
            {
                var otherId = m.SiuntejoId == me ? m.GavetojoId : m.SiuntejoId;
                var otherName = string.Empty;
                try
                {
                    if (Guid.TryParse(otherId, out var otherGuid))
                    {
                        var user = await _db.Naudotojai.FindAsync(otherGuid);
                        if (user != null) otherName = (user.Vardas + " " + user.Pavarde).Trim();
                    }
                }
                catch { }

                if (string.IsNullOrWhiteSpace(otherName))
                {
                    otherName = m.SiuntejoId == me ? m.GavetojoVardas : m.SiuntejoVardas;
                }

                results.Add(new
                {
                    otherId,
                    otherName,
                    lastText = m.Tekstas,
                    lastTime = m.SiustoLaikas.ToString("o"),
                    lastSenderId = m.SiuntejoId,
                });
            }

            await Clients.Caller.SendAsync("Conversations", results);
        }
    }
}
