#!/bin/bash
# This script runs the Kedro pipeline and then renders the Quarto documentation.
set -

echo "" 
echo "-------------------------- Step 1: Running Kedro Pipeline to Generate/Update Data --------------------------"
kedro run  
echo "-------------------------- Kedro Pipeline Finished -------------------------------------------------------"
echo "" 

echo "-------------------------- Step 2: Rendering Quarto Documentation ----------------------------------------"
quarto render docs/
echo "-------------------------- Quarto Documentation Render Finished ------------------------------------------"
echo ""
echo "Output generated in /home/kedro_docker/docs/_site/"
echo "--- Top-level contents of /home/kedro_docker/docs/_site: ---"
ls -l /home/kedro_docker/docs/_site/
echo "----------------------------------------------------------------------------------------------------"
echo ""
