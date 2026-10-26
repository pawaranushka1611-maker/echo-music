FROM debian:bookworm-slim AS build
RUN apt-get update && apt-get install -y --no-install-recommends gcc libc6-dev make && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY server.c music.c json.c json.h music.h ./backend/
RUN gcc -std=c11 -O2 -o echo_server backend/server.c backend/music.c backend/json.c

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends socat ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=build /app/echo_server ./echo_server
COPY app.js index.html styles.css favicon.svg ./static/
COPY *.wav ./media_seed/
RUN mkdir -p data
ENV INTERNAL_PORT=8000
CMD ["sh","-c","mkdir -p /app/data/media && cp -n /app/media_seed/*.wav /app/data/media/ ; rm -rf /app/media; ln -s /app/data/media /app/media; PORT=$INTERNAL_PORT ./echo_server & sleep 1; exec socat TCP-LISTEN:${PORT:-10000},fork,reuseaddr,bind=0.0.0.0 TCP:127.0.0.1:$INTERNAL_PORT"]
