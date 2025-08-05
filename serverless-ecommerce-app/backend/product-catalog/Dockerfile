# Use official Node.js runtime as a parent image
FROM node:14

# Set the working directory
WORKDIR /app

# Copy the current directory contents into the container
COPY . .

# Install dependencies
RUN npm install

# Expose port 8080
EXPOSE 8080

# Start the application
CMD ["node", "src/index.js"]