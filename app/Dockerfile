# syntax=docker/dockerfile:1.6
#
# Multi-stage build for the HPA demo app.
#   stage 1 (builder): install production dependencies in a clean layer
#   stage 2 (runtime): copy the app + node_modules into a slim image
#
# The runtime image runs as a non-root user, which is good practice
# and required by some restricted PodSecurity profiles.

FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install --omit=dev && npm cache clean --force

FROM node:20-alpine AS runtime
WORKDIR /app

# Create non-root user
RUN addgroup -S app && adduser -S app -G app

COPY --from=builder /app/node_modules ./node_modules
COPY server.js ./

USER app

EXPOSE 8080
ENV NODE_ENV=production

# tini-style PID-1 handling via node's built-in signal handling is fine for this demo
CMD ["node", "server.js"]
