# Use Python Alpine as the base image which is much smaller
FROM python:3.11-alpine

# Set working directory
WORKDIR /app

# Set environment variables to reduce Python bytecode generation and enable unbuffered mode
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

# Install only the required build dependencies, install packages, then remove build dependencies
# This creates a single layer that installs and cleans up in one step
COPY requirements.txt .
RUN apk add --no-cache --virtual .build-deps gcc musl-dev && \
    pip install --no-cache-dir -r requirements.txt && \
    apk del .build-deps

# Copy only the necessary application file
COPY app/main.py .

# Expose the port
EXPOSE 8000

# Run the application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
