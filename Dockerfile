# Pinned, minimal base image (never use ":latest" in a real pipeline)
FROM python:3.14-slim

# Create a non-root user — never run the app as root in the container
RUN addgroup --system app && adduser --system --ingroup app app

WORKDIR /app

# Install dependencies first so Docker can cache this layer
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy only what the app needs (see .dockerignore)
COPY app.py .

# Drop root privileges before running the app
USER app

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')" || exit 1

CMD ["python", "app.py"]
