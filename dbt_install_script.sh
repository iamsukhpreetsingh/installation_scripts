#!/bin/bash

# dbt (data build tool) Installation Script
# This script installs dbt globally on your system for access from anywhere

set -e  # Exit on any error

echo "🚀 Starting dbt installation..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detect operating system
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]]; then
        OS="windows"
    else
        print_error "Unsupported operating system: $OSTYPE"
        exit 1
    fi
    print_status "Detected OS: $OS"
}

# Check if Python is installed
check_python() {
    if command -v python3 &> /dev/null; then
        PYTHON_CMD="python3"
    elif command -v python &> /dev/null; then
        PYTHON_CMD="python"
    else
        print_error "Python is not installed. Please install Python 3.8+ first."
        exit 1
    fi
    
    # Check Python version
    PYTHON_VERSION=$($PYTHON_CMD --version 2>&1 | cut -d' ' -f2)
    print_status "Found Python version: $PYTHON_VERSION"
    
    # Check if Python version is 3.8+
    if $PYTHON_CMD -c "import sys; exit(0 if sys.version_info >= (3, 8) else 1)" 2>/dev/null; then
        print_success "Python version is compatible (3.8+)"
    else
        print_error "Python 3.8+ is required. Current version: $PYTHON_VERSION"
        exit 1
    fi
}

# Check if pip is installed
check_pip() {
    if command -v pip3 &> /dev/null; then
        PIP_CMD="pip3"
    elif command -v pip &> /dev/null; then
        PIP_CMD="pip"
    else
        print_error "pip is not installed. Please install pip first."
        exit 1
    fi
    print_status "Found pip: $PIP_CMD"
}

# Install dbt
install_dbt() {
    print_status "Installing dbt..."
    
    # Prompt user for database adapter
    echo ""
    echo "Please select your database adapter:"
    echo "1) PostgreSQL (dbt-postgres)"
    echo "2) Snowflake (dbt-snowflake)"
    echo "3) BigQuery (dbt-bigquery)"
    echo "4) Redshift (dbt-redshift)"
    echo "5) Databricks (dbt-databricks)"
    echo "6) SQL Server (dbt-sqlserver)"
    echo "7) Core only (dbt-core)"
    echo "8) All adapters"
    echo ""
    read -p "Enter your choice (1-8): " choice
    
    case $choice in
        1)
            ADAPTER="dbt-postgres"
            ;;
        2)
            ADAPTER="dbt-snowflake"
            ;;
        3)
            ADAPTER="dbt-bigquery"
            ;;
        4)
            ADAPTER="dbt-redshift"
            ;;
        5)
            ADAPTER="dbt-databricks"
            ;;
        6)
            ADAPTER="dbt-sqlserver"
            ;;
        7)
            ADAPTER="dbt-core"
            ;;
        8)
            ADAPTER="dbt-postgres dbt-snowflake dbt-bigquery dbt-redshift dbt-databricks dbt-sqlserver"
            ;;
        *)
            print_warning "Invalid choice. Installing dbt-core only."
            ADAPTER="dbt-core"
            ;;
    esac
    
    # Install dbt using pip
    print_status "Installing $ADAPTER..."
    $PIP_CMD install --upgrade $ADAPTER
    
    # Verify installation
    if command -v dbt &> /dev/null; then
        print_success "dbt installed successfully!"
        DBT_VERSION=$(dbt --version | head -n1)
        print_status "Installed version: $DBT_VERSION"
    else
        print_error "dbt installation failed or not found in PATH"
        exit 1
    fi
}

# Add dbt to PATH if needed
setup_path() {
    # Check if dbt is in PATH
    if command -v dbt &> /dev/null; then
        print_success "dbt is already accessible from PATH"
        return
    fi
    
    # Try to find dbt installation
    if [[ "$OS" == "macos" ]] || [[ "$OS" == "linux" ]]; then
        # Common locations for pip installed packages
        POSSIBLE_PATHS=(
            "$HOME/.local/bin"
            "/usr/local/bin"
            "$HOME/Library/Python/*/bin"
        )
        
        for path in "${POSSIBLE_PATHS[@]}"; do
            if [[ -f "$path/dbt" ]]; then
                print_status "Found dbt at: $path/dbt"
                
                # Add to PATH in shell profile
                SHELL_PROFILE=""
                if [[ -f "$HOME/.bashrc" ]]; then
                    SHELL_PROFILE="$HOME/.bashrc"
                elif [[ -f "$HOME/.zshrc" ]]; then
                    SHELL_PROFILE="$HOME/.zshrc"
                elif [[ -f "$HOME/.bash_profile" ]]; then
                    SHELL_PROFILE="$HOME/.bash_profile"
                fi
                
                if [[ -n "$SHELL_PROFILE" ]]; then
                    echo "export PATH=\"$path:\$PATH\"" >> "$SHELL_PROFILE"
                    print_success "Added $path to PATH in $SHELL_PROFILE"
                    print_warning "Please restart your terminal or run: source $SHELL_PROFILE"
                fi
                break
            fi
        done
    fi
}

# Create a sample dbt project
create_sample_project() {
    read -p "Would you like to create a sample dbt project? (y/n): " create_sample
    
    if [[ "$create_sample" == "y" ]] || [[ "$create_sample" == "Y" ]]; then
        print_status "Creating sample dbt project..."
        
        # Create project directory
        mkdir -p ~/dbt-projects
        cd ~/dbt-projects
        
        # Initialize dbt project
        dbt init my_first_dbt_project --skip-profile-setup
        
        print_success "Sample project created at: ~/dbt-projects/my_first_dbt_project"
        print_status "To get started:"
        print_status "1. cd ~/dbt-projects/my_first_dbt_project"
        print_status "2. Configure your database connection in ~/.dbt/profiles.yml"
        print_status "3. Run: dbt debug to test your connection"
    fi
}

# Main installation flow
main() {
    print_status "dbt Installation Script"
    print_status "======================="
    
    detect_os
    check_python
    check_pip
    install_dbt
    setup_path
    create_sample_project
    
    echo ""
    print_success "🎉 dbt installation completed!"
    print_status "You can now use dbt from anywhere in your terminal"
    print_status "Run 'dbt --help' to see available commands"
    print_status "Visit https://docs.getdbt.com/ for documentation"
}

# Run the main function
main