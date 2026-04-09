# syntax=docker/dockerfile:1

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Copy csproj and restore as distinct layers
COPY Backend.csproj ./
RUN dotnet restore "Backend.csproj"

# Copy everything else and publish
COPY . ./
RUN dotnet publish "Backend.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app

# Kestrel will listen on all interfaces inside the container
ENV ASPNETCORE_URLS=http://0.0.0.0:8080

# Optional: reduce noisy globalization dependencies
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false

COPY --from=build /app/publish ./

EXPOSE 8080

ENTRYPOINT ["dotnet", "Backend.dll"]
