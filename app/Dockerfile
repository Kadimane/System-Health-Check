# ── Stage 1: install production deps ───────────────────────────────────────
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev

# ── Stage 2: slim runtime ───────────────────────────────────────────────────
FROM node:20-alpine AS runtime
WORKDIR /app

# Run as non-root
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
COPY --from=builder /app/node_modules ./node_modules
COPY server.js .

USER appuser
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

CMD ["node", "server.js"]
