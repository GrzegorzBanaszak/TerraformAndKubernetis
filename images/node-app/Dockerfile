FROM node:16
WORKDIR /app
COPY main.js ./
RUN npm init -y && npm install express
EXPOSE 3000
CMD ["node", "main.js"]