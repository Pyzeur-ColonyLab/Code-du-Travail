FROM python:3.10-slim

# Set working directory
WORKDIR /app

# Set environment variables for better package management
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1

# Install system dependencies with offline-first approach
RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt/lists \
    apt-get update --fix-missing || true && \
    apt-get install -y --no-install-recommends \
    git \
    wget \
    curl \
    build-essential \
    ca-certificates \
    gnupg \
    && apt-get clean

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
