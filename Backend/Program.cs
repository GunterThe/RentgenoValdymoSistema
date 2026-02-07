using Backend.Data;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();

// Register controllers
builder.Services.AddControllers();

// Swagger/OpenAPI for controllers
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Configure DbContext for PostgreSQL
var connectionString = builder.Configuration.GetConnectionString("Default")
                       ?? builder.Configuration["ConnectionStrings:Default"]
                       ?? Environment.GetEnvironmentVariable("CONNECTION_STRING");

if (string.IsNullOrWhiteSpace(connectionString))
{
    throw new InvalidOperationException("Connection string 'Default' not found. Set it in appsettings or environment variable 'CONNECTION_STRING'.");
}

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(connectionString));

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.MapControllers();

app.Run();