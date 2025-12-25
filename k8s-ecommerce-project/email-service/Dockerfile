FROM python:3.9-slim

# Best Practice: Update OS and install minimal tools only if needed
# For this app, we skip this to keep the image small (Attack Surface Reduction).

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .
EXPOSE 8080

# Create a non-root user and change ownership
RUN useradd -m appuser && chown -R appuser /app
USER appuser

CMD ["python", "app.py"]