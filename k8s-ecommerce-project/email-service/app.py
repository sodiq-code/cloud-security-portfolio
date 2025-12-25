"""
Email Service - A simple Flask microservice for the K8s E-commerce Project.

This service demonstrates a basic containerized application that can be
deployed as multiple replicas in a Kubernetes cluster.
"""

from flask import Flask
import socket

# Initialize the Flask application
app = Flask(__name__)


@app.route('/')
def hello():
    """
    Root endpoint that returns a greeting message.
    
    Returns:
        str: A greeting message including the container's hostname,
             which serves as a unique identifier to show which
             replica/pod handled the request (useful for demonstrating
             load balancing in Kubernetes).
    """
    # Get the container's hostname (in Kubernetes, this is typically the pod name)
    container_id = socket.gethostname()
    
    return f"Hello! This is the Email Service running on container: {container_id}\n"


if __name__ == "__main__":
    # Run the Flask development server
    # host='0.0.0.0' - Listen on all network interfaces (required for containers)
    # port=8080 - Standard alternative HTTP port for containerized applications
    app.run(host='0.0.0.0', port=8080)