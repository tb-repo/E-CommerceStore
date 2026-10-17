FROM node:18-alpine
ENV NODE_ENV=production
WORKDIR /app
COPY package*.json ./
RUN npm install --production && npm cache clean --force
COPY --chown=node:node . .
USER node
EXPOSE 3003
CMD ["node", "server.js"]