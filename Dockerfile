# Base Image
FROM ubuntu:24.04

# Working Directory 
WORKDIR /app

# Copy Project 
COPY . . 

# Make Script Executable 
RUN chmod +x scripts/watcher.sh

# Default command
CMD ["bash", "-x", "./scripts/watcher.sh"]
