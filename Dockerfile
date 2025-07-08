FROM python:3.10-slim

# Set working directory
WORKDIR /app

# Set environment variables for better package management
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1

# Install system dependencies with better error handling
RUN apt-get update --fix-missing && \
    apt-get install -y --no-install-recommends \
    git \
    wget \
    curl \
    build-essential \
    ca-certificates \
    gnupg \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first to leverage Docker cache
COPY requirements.txt .

# Install Python dependencies with retry mechanism
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create necessary directories
RUN mkdir -p logs cache

# Set proper permissions
RUN chmod +x *.sh

# Expose port (if needed for health checks)
EXPOSE 8000

# Run the bot using the orchestration script
CMD ["python", "run.py", "--mode", "both"]
