# Use a stable Python image (3.10 works well with Prophet)
FROM python:3.10-slim

# Set working directory
WORKDIR /app

# Install system packages Prophet & pystan require
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
    g++ \
    make \
    libatlas-base-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy only backend requirements to leverage Docker layer caching
COPY backend/requirements.txt .

# Upgrade pip and install dependencies
RUN pip install --no-cache-dir --upgrade pip setuptools wheel
RUN pip install --no-cache-dir -r requirements.txt

# Copy your backend app code into the container
COPY backend/ .

# Expose port 5000 for Flask
EXPOSE 5000

# Run the Flask app with Gunicorn on port 5000
CMD ["gunicorn", "app:app", "--bind", "0.0.0.0:5000"]
