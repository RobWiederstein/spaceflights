#!/bin/bash
# --- run_and_render.sh ---
echo "-------------------------- Step 1: Running Kedro Pipeline to Generate/Update Data --------------------------"
kedro run
KEDRO_EXIT_CODE=$?
if [ $KEDRO_EXIT_CODE -ne 0 ]; then
  echo "ERROR: Kedro pipeline failed with exit code $KEDRO_EXIT_CODE"
  exit $KEDRO_EXIT_CODE
fi
echo "-------------------------- Kedro Pipeline Finished -------------------------------------------------------"
echo ""
echo "-------------------------- Step 2: Rendering Quarto Documentation ----------------------------------------"

# --- Define the expected path to the debug log ---
# This should match where the Python chunk saves it.
# If PROJECT_ROOT_PATH in container is /home/kedro_docker, and QMD is in /home/kedro_docker/docs/
# then the log file is /home/kedro_docker/docs/fig_matrix_debug.log

# Determine where Quarto is run from to set the correct path for the debug log
# Assuming your Quarto project is in the 'docs' subdirectory of your Kedro project root.
# The WORKDIR in your Dockerfile is likely /home/kedro_docker (your Kedro project root).

QUARTO_PROJECT_DIR="docs" # This is where _quarto.yml and index.qmd live, relative to project root
DEBUG_LOG_FILE_IN_DOCS_DIR="fig_matrix_debug.log" # The name of the log file Python creates in QUARTO_PROJECT_DIR
DEBUG_LOG_FULL_PATH="$QUARTO_PROJECT_DIR/$DEBUG_LOG_FILE_IN_DOCS_DIR"

# Remove old debug log if it exists, to ensure a fresh one from this run
rm -f "$DEBUG_LOG_FULL_PATH"
echo "Attempting to remove old debug log (if any) at $DEBUG_LOG_FULL_PATH"

# Run Quarto (render the project in the 'docs' directory)
# Quarto's current working directory will typically be the project directory it's rendering.
quarto render "$QUARTO_PROJECT_DIR"
QUARTO_EXIT_CODE=$?

echo "-------------------------- Quarto Documentation Render Finished (Exit Code: $QUARTO_EXIT_CODE) -------------------"
echo ""
echo "--- Contents of Python Chunk's Debug Log ($DEBUG_LOG_FULL_PATH) ---"
if [ -f "$DEBUG_LOG_FULL_PATH" ]; then
    cat "$DEBUG_LOG_FULL_PATH"
else
    echo "Python chunk debug log NOT FOUND at '$DEBUG_LOG_FULL_PATH'"
    # Check fallback location if Python couldn't use PROJECT_ROOT_PATH and used CWD
    FALLBACK_DEBUG_LOG_PATH_IN_DOCS_DIR="fig_matrix_debug_fallback.log"
    FALLBACK_DEBUG_LOG_FULL_PATH="$QUARTO_PROJECT_DIR/$FALLBACK_DEBUG_LOG_PATH_IN_DOCS_DIR"
    if [ -f "$FALLBACK_DEBUG_LOG_FULL_PATH" ]; then
        echo "Found fallback debug log at '$FALLBACK_DEBUG_LOG_FULL_PATH':"
        cat "$FALLBACK_DEBUG_LOG_FULL_PATH"
    else
        echo "Fallback debug log also not found at '$FALLBACK_DEBUG_LOG_FULL_PATH'."
    fi
fi
echo "---------------------------------------------------------------------"
echo ""

# Your existing _site listing
SITE_DIR_PATH="$QUARTO_PROJECT_DIR/_site" # Assuming default _site output
echo "Output generated in /home/kedro_docker/$SITE_DIR_PATH" 
echo "--- Top-level contents of /home/kedro_docker/$SITE_DIR_PATH: ---"
ls -Al "/home/kedro_docker/$SITE_DIR_PATH" # Use absolute path for ls for clarity
echo "----------------------------------------------------------------------------------------------------"
echo ""

# Exit with Quarto's exit code, or Kedro's if it failed earlier (already handled)
exit $QUARTO_EXIT_CODE