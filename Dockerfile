# Dockerfile for Smithery deployment — multi-stage build

# === Stage 1: Builder ===
FROM node:20-slim AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install ALL dependencies (including dev for build)
RUN npm ci

# Copy source files
COPY src/ ./src/
COPY tsconfig.json ./

# Build TypeScript
RUN npm run build

# === Stage 2: Runtime ===
FROM node:20-slim

# Install dependencies for Chromium (required by patchright)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libnss3 \
    libnspr4 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libdbus-1-3 \
    libxkbcommon0 \
    libatspi2.0-0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libasound2 \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libcairo2 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy only production artifacts from builder
COPY --from=builder /app/dist/ ./dist/
COPY package*.json ./

# Install production dependencies only
RUN npm ci --omit=dev

# Install browser
RUN npx patchright install chromium

# Create data directory
RUN mkdir -p /app/data && chown -R node:node /app

# Set user for security
USER node

# Default command
CMD ["node", "dist/index.js"]
