# syntax=docker/dockerfile:1

# Build Flutter web
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app/frontend

COPY frontend/pubspec.yaml frontend/pubspec.lock* ./
RUN flutter pub get

COPY frontend/ ./

# Build with API_BASE empty so requests go to same origin (/api/*), which nginx proxies.
RUN flutter build web --release --dart-define=API_BASE=

# Serve with nginx
FROM nginx:alpine
COPY --from=build /app/frontend/build/web /usr/share/nginx/html
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
