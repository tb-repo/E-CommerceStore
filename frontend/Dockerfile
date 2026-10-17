# Build Stage
FROM node:18-alpine AS builder
WORKDIR /app
# Prevent Webpack OOM by disabling heavy source maps
ENV GENERATE_SOURCEMAP=false
ENV NODE_OPTIONS="--max-old-space-size=1024"
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Production Stage
FROM nginx:alpine
COPY --from=builder /app/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80 3000
CMD ["nginx", "-g", "daemon off;"]