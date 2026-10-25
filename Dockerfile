# Deployment-only file for Render. Builds your unmodified C source as-is.
FROM debian:bookworm-slim AS build
RUN apt-get update && apt-get install -y --no-install-recommends gcc libc6-dev make && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY backend ./backend
RUN gcc -std=c11 -O2 -o echo_server backend/server.c backend/music.c backend/json.c

FROM debian:bookworm-slim
# The C server only listens on 127.0.0.1 (by design, unchanged). socat exposes it on Render's public $PORT.
RUN apt-get update && apt-get install -y --no-install-recommends socat ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=build /app/echo_server ./echo_server
COPY static ./static
RUN mkdir -p data media
ENV INTERNAL_PORT=8000
CMD ["sh","-c","PORT=$INTERNAL_PORT ./echo_server & sleep 1; exec socat TCP-LISTEN:${PORT:-10000},fork,reuseaddr,bind=0.0.0.0 TCP:127.0.0.1:$INTERNAL_PORT"]
