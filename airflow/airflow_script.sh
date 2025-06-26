#!/bin/bash

# Apache Airflow Installation Script for Ubuntu
# This script installs Apache Airflow with all necessary dependencies

set -e  # Exit on any error

echo "🚀 Starting Apache Airflow installation on Ubuntu..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root. Please run as a regular user."
   exit 1
fi

# Update system packages
print_header "Updating System Packages"
sudo apt update && sudo apt upgrade -y

# Install system dependencies
print_header "Installing System Dependencies"
sudo apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    build-essential \
    libssl-dev \
    libffi-dev \
    libpq-dev \
    default-libmysqlclient-dev \
    pkg-config \
    git \
    curl \
    wget \
    software-properties-common

# Check Python version
PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d'.' -f1)
PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d'.' -f2)
print_status "Python version: $PYTHON_VERSION"

# Check if Python version is 3.8 or higher
if [[ $PYTHON_MAJOR -lt 3 ]] || [[ $PYTHON_MAJOR -eq 3 && $PYTHON_MINOR -lt 8 ]]; then
    print_error "Python 3.8+ is required. Current version: $PYTHON_VERSION"
    exit 1
fi

print_status "✅ Python version check passed!"

# Set Airflow home directory
export AIRFLOW_HOME=~/airflow
print_status "Setting AIRFLOW_HOME to: $AIRFLOW_HOME"

# Create airflow directory
mkdir -p $AIRFLOW_HOME

# Create Python virtual environment
print_header "Creating Python Virtual Environment"
VENV_PATH=~/airflow-venv
python3 -m venv $VENV_PATH
source $VENV_PATH/bin/activate

# Upgrade pip
print_status "Upgrading pip..."
pip install --upgrade pip

# Set Airflow version and constraints
AIRFLOW_VERSION=2.8.1
PYTHON_VERSION="$(python --version | cut -d " " -f 2 | cut -d "." -f 1-2)"
CONSTRAINT_URL="https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-${PYTHON_VERSION}.txt"

print_status "Installing Airflow version: $AIRFLOW_VERSION"
print_status "Using constraints for Python: $PYTHON_VERSION"

# Install Apache Airflow
print_header "Installing Apache Airflow"
pip install "apache-airflow==${AIRFLOW_VERSION}" --constraint "${CONSTRAINT_URL}"

# Install additional providers (optional but useful)
print_header "Installing Additional Airflow Providers"
pip install apache-airflow-providers-postgres
pip install apache-airflow-providers-mysql
pip install apache-airflow-providers-http
pip install apache-airflow-providers-ftp

# Initialize Airflow database
print_header "Initializing Airflow Database"
airflow db init

# Create admin user
print_header "Creating Admin User"
echo "Creating admin user for Airflow..."
airflow users create \
    --username admin \
    --firstname Admin \
    --lastname User \
    --role Admin \
    --email admin@example.com \
    --password admin

# Create systemd service files
print_header "Creating Systemd Service Files"

# Create webserver service
sudo tee /etc/systemd/system/airflow-webserver.service > /dev/null <<EOF
[Unit]
Description=Airflow webserver daemon
After=network.target

[Service]
Environment=AIRFLOW_HOME=${AIRFLOW_HOME}
User=${USER}
Group=${USER}
Type=simple
ExecStart=${VENV_PATH}/bin/airflow webserver --port 8080
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

# Create scheduler service
sudo tee /etc/systemd/system/airflow-scheduler.service > /dev/null <<EOF
[Unit]
Description=Airflow scheduler daemon
After=network.target

[Service]
Environment=AIRFLOW_HOME=${AIRFLOW_HOME}
User=${USER}
Group=${USER}
Type=simple
ExecStart=${VENV_PATH}/bin/airflow scheduler
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
sudo systemctl daemon-reload

# Create environment setup script
print_header "Creating Environment Setup Script"
cat > ~/airflow-env.sh <<EOF
#!/bin/bash
# Airflow Environment Setup Script

export AIRFLOW_HOME=~/airflow
source ~/airflow-venv/bin/activate

echo "Airflow environment activated!"
echo "AIRFLOW_HOME: \$AIRFLOW_HOME"
echo "Virtual environment: ~/airflow-venv"
echo ""
echo "Available commands:"
echo "  airflow webserver    - Start web server"
echo "  airflow scheduler    - Start scheduler"
echo "  airflow --help      - Show help"
EOF

chmod +x ~/airflow-env.sh

# Create sample DAG
print_header "Creating Sample DAG"
mkdir -p $AIRFLOW_HOME/dags

cat > $AIRFLOW_HOME/dags/hello_world_dag.py <<EOF
from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator

def hello_world():
    print("Hello World from Airflow!")
    return "Hello World!"

def current_time():
    print(f"Current time: {datetime.now()}")
    return datetime.now()

# Default arguments
default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

# Create DAG
dag = DAG(
    'hello_world_dag',
    default_args=default_args,
    description='A simple Hello World DAG',
    schedule_interval=timedelta(days=1),
    catchup=False,
    tags=['example', 'hello-world'],
)

# Create tasks
hello_task = PythonOperator(
    task_id='hello_world_task',
    python_callable=hello_world,
    dag=dag,
)

time_task = PythonOperator(
    task_id='current_time_task',
    python_callable=current_time,
    dag=dag,
)

# Set task dependencies
hello_task >> time_task
EOF

print_header "Installation Complete!"
print_status "✅ Apache Airflow has been successfully installed!"
echo ""
print_status "📁 Airflow Home: $AIRFLOW_HOME"
print_status "🐍 Virtual Environment: $VENV_PATH"
print_status "👤 Admin User: admin / admin"
print_status "🌐 Web UI will be available at: http://localhost:8080"
echo ""
print_warning "Next Steps:"
echo "1. Activate the environment: source ~/airflow-env.sh"
echo "2. Start the webserver: airflow webserver --port 8080"
echo "3. Start the scheduler: airflow scheduler"
echo "4. Access the web UI at http://localhost:8080"
echo ""
print_status "To use systemd services:"
echo "  sudo systemctl enable airflow-webserver"
echo "  sudo systemctl enable airflow-scheduler"
echo "  sudo systemctl start airflow-webserver"
echo "  sudo systemctl start airflow-scheduler"
echo ""
print_status "🎉 Happy Airflowing!"
