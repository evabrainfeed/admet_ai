# Set the base image to use, which is "mambaorg/micromamba:1.5.1"
FROM mambaorg/micromamba:1.5.1

# Create a named volume at "/opt/admet_ai/data" in the container to persist data across container runs
VOLUME /opt/admet_ai/data

# Switch to the root user to perform installation and directory ownership tasks
USER root

# Update the package list and install "git" package, then remove unnecessary cached files to reduce image size
RUN apt-get update && \
    apt-get install -y git && \
    rm -rf /var/lib/{apt,dpkg,cache,log}

# Copy the application source code into /opt/admet_ai and set explicit directory ownership
COPY . /opt/admet_ai
RUN chown -R $MAMBA_USER:$MAMBA_USER /opt/admet_ai

# Switch back to the non-root mamba user
USER $MAMBA_USER

# Create a new conda environment named "base" and install dependencies
RUN micromamba install -y -n base -c conda-forge python=3.12 xorg-libxrender && \
    micromamba clean --all --yes

# Set working directory
WORKDIR /opt/admet_ai

# Install the Python package standardly (removed editable '-e' flag to prevent permission/metadata write failures)
RUN /opt/conda/bin/python -m pip install .[web] && \
    /opt/conda/bin/python -m pip cache purge

# Expose port 5000 for Cloud Run / Container traffic
EXPOSE 5000

# Set working directory to the Flask/WSGI app location
WORKDIR /opt/admet_ai/admet_ai/web

# Ensure container runs under the non-root MAMBA_USER (Best Practice for Cloud Run)
USER $MAMBA_USER

# Default command to start Gunicorn using the virtual environment's Python binary
CMD ["/opt/conda/bin/gunicorn", "--bind", "0.0.0.0:5000", "wsgi:build_app()"]# Change the working directory to "/opt/admet_ai/admet_ai/web"
WORKDIR /opt/admet_ai/admet_ai/web

# Switch back to the root user to execute the final command
USER root

# The default command to run when the container starts.
# It uses Gunicorn to serve the application on 0.0.0.0:5000
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "wsgi:build_app()"]
