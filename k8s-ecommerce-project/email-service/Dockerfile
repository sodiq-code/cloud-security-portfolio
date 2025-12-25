# 1. Base Image: Start with a lightweight OS that has Python installed
# Think of this as buying a laptop with Windows/Linux pre-installed.
FROM python:3.9-slim

# 2. Working Directory: Create a folder inside the container
# This is like creating a "C:/app" folder on that laptop.
WORKDIR /app

# 3. Copy Files: Move our requirements file into the container
COPY requirements.txt .

# 4. Install Dependencies: Run the installation command inside the container
RUN pip install --no-cache-dir -r requirements.txt

# 5. Copy Code: Move our app.py into the container
COPY app.py .

# 6. Expose Port: Tell Docker this app listens on port 8080
EXPOSE 8080


# 7. Create a non-root user and change ownership in one step
RUN useradd -m appuser && chown -R appuser /app

# 8. Switch to the new user
USER appuser

# 9. Startup Command
CMD ["python", "app.py"]