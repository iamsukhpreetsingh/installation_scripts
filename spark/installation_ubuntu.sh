#!/bin/bash

# PySpark + Jupyter Notebook Installation Script for Ubuntu 20.04 LTS
# This script installs Java, Python, PySpark, and Jupyter Notebook

set -e  # Exit on any error

echo "========================================="
echo "PySpark + Jupyter Installation Script"
echo "Ubuntu"
echo "========================================="

# Update system packages
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Java 8 (required for Spark)
echo "Installing Java 8..."
sudo apt install -y openjdk-8-jdk

# Set JAVA_HOME
echo "Setting JAVA_HOME..."
echo 'export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64' >> ~/.bashrc
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

# Install Python and pip
echo "Installing Python and pip..."
sudo apt install -y python3 python3-pip python3-venv

# Create a virtual environment for PySpark
echo "Creating virtual environment..."
python3 -m venv ~/pyspark-env
source ~/pyspark-env/bin/activate

# Upgrade pip
pip install --upgrade pip

# Install required Python packages
echo "Installing Python packages..."
pip install jupyter notebook ipython
pip install pyspark
pip install pandas numpy matplotlib seaborn plotly
pip install findspark

# Download and install Spark (optional - PySpark includes Spark)
echo "Setting up Spark environment..."
cd ~
SPARK_VERSION="3.5.0"
HADOOP_VERSION="3"

# Download Spark
wget -q https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz

# Extract Spark
tar -xzf spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz
sudo mv spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} /opt/spark

# Set Spark environment variables
echo 'export SPARK_HOME=/opt/spark' >> ~/.bashrc
echo 'export PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin' >> ~/.bashrc
echo 'export PYSPARK_DRIVER_PYTHON=jupyter' >> ~/.bashrc
echo 'export PYSPARK_DRIVER_PYTHON_OPTS="notebook"' >> ~/.bashrc
echo 'export PYSPARK_PYTHON=python3' >> ~/.bashrc

# Source the bashrc to apply changes
source ~/.bashrc

# Clean up downloaded files
rm ~/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz

# Create a sample PySpark notebook
echo "Creating sample PySpark notebook..."
mkdir -p ~/pyspark-notebooks
cd ~/pyspark-notebooks

# Create a sample notebook file
cat > pyspark_sample.ipynb << 'EOF'
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "# PySpark Sample Notebook\n",
    "This notebook demonstrates basic PySpark functionality."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Import necessary libraries\n",
    "import findspark\n",
    "findspark.init()\n",
    "\n",
    "from pyspark.sql import SparkSession\n",
    "import pandas as pd"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Create Spark session\n",
    "spark = SparkSession.builder \\\n",
    "    .appName(\"PySpark Sample\") \\\n",
    "    .master(\"local[*]\") \\\n",
    "    .getOrCreate()\n",
    "\n",
    "print(f\"Spark version: {spark.version}\")\n",
    "print(f\"Spark UI available at: http://localhost:4040\")"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Create sample data\n",
    "data = [(\"Alice\", 25), (\"Bob\", 30), (\"Charlie\", 35)]\n",
    "columns = [\"Name\", \"Age\"]\n",
    "\n",
    "# Create DataFrame\n",
    "df = spark.createDataFrame(data, columns)\n",
    "df.show()"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Basic operations\n",
    "print(\"DataFrame Schema:\")\n",
    "df.printSchema()\n",
    "\n",
    "print(\"\\nDataFrame Count:\")\n",
    "print(df.count())\n",
    "\n",
    "print(\"\\nFiltered DataFrame (Age > 25):\")\n",
    "df.filter(df.Age > 25).show()"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Stop Spark session\n",
    "spark.stop()"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3",
   "language": "python",
   "name": "python3"
  },
  "language_info": {
   "codemirror_mode": {
    "name": "ipython",
    "version": 3
   },
   "file_extension": ".py",
   "mimetype": "text/x-python",
   "name": "python",
   "nbconvert_exporter": "python",
   "pygments_lexer": "ipython3",
   "version": "3.8.5"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 4
}
EOF

# Create a startup script for easy access
cat > ~/start_pyspark_jupyter.sh << 'EOF'
#!/bin/bash
# Activate virtual environment
source ~/pyspark-env/bin/activate

# Set environment variables
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export SPARK_HOME=/opt/spark
export PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin
export PYSPARK_DRIVER_PYTHON=jupyter
export PYSPARK_DRIVER_PYTHON_OPTS="notebook"
export PYSPARK_PYTHON=python3

# Start Jupyter Notebook
echo "Starting Jupyter Notebook with PySpark..."
echo "Navigate to: http://localhost:8888"
cd ~/pyspark-notebooks
jupyter notebook --ip=0.0.0.0 --port=8888 --no-browser --allow-root
EOF

chmod +x ~/start_pyspark_jupyter.sh

echo "========================================="
echo "Installation Complete!"
echo "========================================="
echo ""
echo "To start using PySpark with Jupyter:"
echo "1. Run: source ~/pyspark-env/bin/activate"
echo "2. Run: ~/start_pyspark_jupyter.sh"
echo ""
echo "Or simply run: ~/start_pyspark_jupyter.sh"
echo ""
echo "Your notebooks will be saved in: ~/pyspark-notebooks/"
echo "A sample notebook has been created: pyspark_sample.ipynb"
echo ""
echo "Jupyter will be available at: http://localhost:8888"
echo "Spark UI will be available at: http://localhost:4040 (when Spark is running)"
echo ""
echo "Environment Variables Set:"
echo "- JAVA_HOME: $JAVA_HOME"
echo "- SPARK_HOME: /opt/spark"
echo ""
echo "Happy Sparking! 🚀"
