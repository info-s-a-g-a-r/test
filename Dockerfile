# Use a lightweight Nginx base image
FROM nginx:alpine

# Copy the file to the Nginx HTML directory
COPY file\ 1 /usr/share/nginx/html/index.html

# Expose port 80
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
