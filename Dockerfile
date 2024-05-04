# Use an official Python runtime as a parent image
FROM python:3.11-slim

# Set the working directory in the container
WORKDIR /usr/src/app

# Set environment variables to prevent Python from writing pyc files to disc and buffering stdout and stderr
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    FLASK_APP=weather_app/app.py \
    FLASK_RUN_HOST=0.0.0.0 \
    FLASK_RUN_PORT=8080

# Install system dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends gcc libpq-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Poetry
RUN pip install --upgrade pip \
    && pip install poetry

# Configure Poetry: Disable virtual environments creation as dependencies are installed globally
RUN poetry config virtualenvs.create false

# Install project dependencies by copying only the necessary files and installing dependencies
COPY poetry.lock pyproject.toml ./
RUN poetry install --no-dev --no-interaction --no-ansi

# Create a non-root user and switch to it
# Set the user ID and group ID to 1000 to align with your Kubernetes fsGroup
RUN groupadd -g 1000 appgroup && \
    useradd -r -u 1000 -g appgroup -m appuser

# Switch to the non-root user
USER appuser

# Copy the rest of the application with appropriate ownership
COPY --chown=appuser:appgroup weather_app ./weather_app

# Expose the port the app runs on
EXPOSE 8080

# Command to run the Flask application using the environment variables set
CMD ["flask", "run"]
