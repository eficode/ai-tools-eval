FROM python:3.12-slim

WORKDIR /app

# Install wget for healthcheck
RUN apt-get update && apt-get install -y wget && rm -rf /var/lib/apt/lists/*

# Install dependencies
COPY requirements.txt README.md /app/
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY . /app/

# Create database directory
RUN mkdir -p /app/data

# Expose port
EXPOSE 8000

# Run the application
CMD ["uvicorn", "fastapi_demo.main:app", "--host", "0.0.0.0", "--port", "8000"]