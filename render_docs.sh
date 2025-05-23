#!/bin/bash
# Script to render Quarto documentation

set -e # Exit immediately if a command exits with a non-zero status

echo ">>> Navigating to project root (if not already there, though WORKDIR should handle this)..."
# cd /home/kedro_docker # WORKDIR in Dockerfile should make this the default

echo ">>> Starting Quarto documentation render for the 'docs' directory..."
quarto render docs/

echo ">>> Quarto documentation render finished."
echo "Output should be in /home/kedro_docker/docs/_site/"
ls -R /home/kedro_docker/docs/_site/ # List the output for verification
