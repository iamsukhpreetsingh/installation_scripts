#!/bin/bash

# PySpark Jupyter Startup Script
# Save this as ~/start_pyspark_jupyter.sh

echo "Starting PySpark with Jupyter Notebook..."

# Check if virtual environment exists
if [ ! -d "$HOME/pyspark-env" ]; then
    echo "Error: PySpark virtual environment not found at ~/pyspark-env"
    echo "Please run the installation script first."
    exit 1
fi

# Activate virtual environment
echo "Activating virtual environment..."
source ~/pyspark-env/bin/activate

# Set environment variables
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export SPARK_HOME=/opt/spark
export PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin
export PYSPARK_DRIVER_PYTHON=jupyter
export PYSPARK_DRIVER_PYTHON_OPTS="notebook"
export PYSPARK_PYTHON=python3

# Create notebooks directory if it doesn't exist
mkdir -p ~/pyspark-notebooks

# Check if Jupyter is installed
if ! command -v jupyter &> /dev/null; then
    echo "Error: Jupyter is not installed in the virtual environment"
    echo "Please run: pip install jupyter notebook"
    exit 1
fi

# Start Jupyter Notebook
echo "Starting Jupyter Notebook..."
echo "Navigate to: http://localhost:8888"
echo "Press Ctrl+C to stop"
echo ""

cd ~/pyspark-notebooks
jupyter notebook --ip=0.0.0.0 --port=8888 --no-browser --allow-root
