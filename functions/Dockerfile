FROM node:20-slim

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY . .

# Build TypeScript
RUN npm run build

# Expose port
ENV PORT=8080
EXPOSE 8080

# Start the functions framework
CMD ["npm", "run", "serve"]

