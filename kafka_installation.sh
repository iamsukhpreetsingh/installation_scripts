#!/bin/bash

# Kafka Installation Script
# This script installs Apache Kafka on your local system

set -e

echo "🚀 Starting Kafka Installation..."

# Check if Java is installed
check_java() {
    if command -v java &> /dev/null; then
        JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
        echo "✅ Java is installed: $JAVA_VERSION"
    else
        echo "❌ Java is not installed. Installing OpenJDK 11..."
        # Install Java based on OS
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            sudo apt update && sudo apt install -y openjdk-11-jdk
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            brew install openjdk@11
        else
            echo "Please install Java 11 or higher manually"
            exit 1
        fi
    fi
}

# Create Kafka directory
setup_directory() {
    KAFKA_HOME="$HOME/kafka"
    echo "📁 Setting up Kafka directory at $KAFKA_HOME"
    mkdir -p $KAFKA_HOME
    cd $KAFKA_HOME
}

# Download and extract Kafka
download_kafka() {
    KAFKA_VERSION="2.13-3.7.0"
    KAFKA_FILE="kafka_$KAFKA_VERSION.tgz"
    
    # Try multiple mirror URLs
    KAFKA_URLS=(
        "https://archive.apache.org/dist/kafka/3.7.0/kafka_$KAFKA_VERSION.tgz"
        "https://downloads.apache.org/kafka/3.7.0/kafka_$KAFKA_VERSION.tgz"
        "https://dlcdn.apache.org/kafka/3.7.0/kafka_$KAFKA_VERSION.tgz"
    )
    
    echo "⬇️  Downloading Kafka $KAFKA_VERSION..."
    
    # Try each URL until one works
    for url in "${KAFKA_URLS[@]}"; do
        echo "Trying: $url"
        if curl -L -f -o "$KAFKA_FILE" "$url"; then
            echo "✅ Download successful"
            break
        else
            echo "❌ Failed, trying next URL..."
            rm -f "$KAFKA_FILE"
        fi
    done
    
    # Check if download was successful
    if [ ! -f "$KAFKA_FILE" ]; then
        echo "❌ All download attempts failed. Please check your internet connection."
        exit 1
    fi
    
    # Verify the file is a valid gzip
    if ! file "$KAFKA_FILE" | grep -q "gzip compressed"; then
        echo "❌ Downloaded file is not a valid gzip archive"
        echo "File info: $(file $KAFKA_FILE)"
        exit 1
    fi
    
    echo "📦 Extracting Kafka..."
    tar -xzf "$KAFKA_FILE"
    
    # Check if extraction was successful
    if [ ! -d "kafka_$KAFKA_VERSION" ]; then
        echo "❌ Extraction failed"
        exit 1
    fi
    
    mv kafka_$KAFKA_VERSION/* .
    rm -rf kafka_$KAFKA_VERSION "$KAFKA_FILE"
    
    echo "✅ Kafka extracted successfully"
}

# Create convenient scripts
create_scripts() {
    echo "📝 Creating convenience scripts..."
    
    # Start Zookeeper script
    cat > start-zookeeper.sh << 'EOF'
#!/bin/bash
cd $(dirname $0)
echo "Starting Zookeeper..."
bin/zookeeper-server-start.sh config/zookeeper.properties
EOF
    
    # Start Kafka script
    cat > start-kafka.sh << 'EOF'
#!/bin/bash
cd $(dirname $0)
echo "Starting Kafka..."
bin/kafka-server-start.sh config/server.properties
EOF
    
    # Stop services script
    cat > stop-kafka.sh << 'EOF'
#!/bin/bash
cd $(dirname $0)
echo "Stopping Kafka..."
bin/kafka-server-stop.sh
echo "Stopping Zookeeper..."
bin/zookeeper-server-stop.sh
EOF
    
    # Make scripts executable
    chmod +x start-zookeeper.sh start-kafka.sh stop-kafka.sh
    
    echo "✅ Scripts created successfully"
}

# Update PATH
update_path() {
    echo "🔧 Updating PATH..."
    KAFKA_BIN="$KAFKA_HOME/bin"
    
    # Add to .bashrc or .zshrc
    if [ -n "$ZSH_VERSION" ]; then
        SHELL_RC="$HOME/.zshrc"
    else
        SHELL_RC="$HOME/.bashrc"
    fi
    
    if ! grep -q "KAFKA_HOME" "$SHELL_RC" 2>/dev/null; then
        echo "" >> "$SHELL_RC"
        echo "# Kafka" >> "$SHELL_RC"
        echo "export KAFKA_HOME=$KAFKA_HOME" >> "$SHELL_RC"
        echo "export PATH=\$PATH:\$KAFKA_HOME/bin" >> "$SHELL_RC"
        echo "✅ Added Kafka to PATH in $SHELL_RC"
    else
        echo "✅ Kafka already in PATH"
    fi
}

# Main installation
main() {
    echo "🔍 Checking prerequisites..."
    check_java
    
    echo "📁 Setting up directories..."
    setup_directory
    
    echo "⬇️  Downloading Kafka..."
    download_kafka
    
    echo "📝 Creating scripts..."
    create_scripts
    
    echo "🔧 Updating PATH..."
    update_path
    
    echo ""
    echo "🎉 Kafka installation completed successfully!"
    echo ""
    echo "📍 Installation location: $KAFKA_HOME"
    echo ""
    echo "Next steps:"
    echo "1. Restart your terminal or run: source ~/.bashrc (or ~/.zshrc)"
    echo "2. Start Zookeeper: $KAFKA_HOME/start-zookeeper.sh"
    echo "3. Start Kafka: $KAFKA_HOME/start-kafka.sh"
    echo ""
    echo "Happy streaming! 🚀"
}

main "$@"
