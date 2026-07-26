# Example Dockerfile — replace with your actual app's build steps.
# This example assumes a simple Node.js app; swap for Python/Java/etc. as needed.

FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

EXPOSE 8080

CMD ["npm", "start"]
