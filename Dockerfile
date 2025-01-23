FROM python:3.8

# Set a directory for the app
WORKDIR /usr/src/app

# Copy all the files to the container
COPY . .

# Install dependencies
RUN pip install -r requirements.txt

# Install AWS CLI and jq
RUN apt-get update && apt-get install -y \
    awscli jq \
    && rm -rf /var/lib/apt/lists/*

# Expose port
EXPOSE 5000

# Remove CMD, handle it in docker-compose.yml
