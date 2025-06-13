from flask import Flask, jsonify, Response
import json
import time
import random
import threading
from datetime import datetime
import uuid

app = Flask(__name__)

# Sample data generators
def generate_user_activity():
    """Generate random user activity data"""
    users = ['user_001', 'user_002', 'user_003', 'user_004', 'user_005']
    actions = ['login', 'logout', 'purchase', 'view_product', 'add_to_cart', 'search']
    products = ['laptop', 'phone', 'tablet', 'headphones', 'keyboard', 'mouse']
    
    return {
        'id': str(uuid.uuid4()),
        'timestamp': datetime.now().isoformat(),
        'user_id': random.choice(users),
        'action': random.choice(actions),
        'product': random.choice(products) if random.choice(actions) in ['purchase', 'view_product'] else None,
        'amount': round(random.uniform(10.0, 1000.0), 2) if random.choice(actions) == 'purchase' else None,
        'session_duration': random.randint(1, 300),
        'page_views': random.randint(1, 20)
    }

def generate_sensor_data():
    """Generate random IoT sensor data"""
    sensor_types = ['temperature', 'humidity', 'pressure', 'light']
    locations = ['room_A', 'room_B', 'room_C', 'outdoor', 'warehouse']
    
    sensor_type = random.choice(sensor_types)
    value_ranges = {
        'temperature': (15.0, 35.0),
        'humidity': (30.0, 80.0),
        'pressure': (990.0, 1030.0),
        'light': (0.0, 1000.0)
    }
    
    min_val, max_val = value_ranges[sensor_type]
    
    return {
        'id': str(uuid.uuid4()),
        'timestamp': datetime.now().isoformat(),
        'sensor_id': f"{sensor_type}_{random.randint(1, 10):03d}",
        'sensor_type': sensor_type,
        'location': random.choice(locations),
        'value': round(random.uniform(min_val, max_val), 2),
        'unit': {'temperature': 'celsius', 'humidity': '%', 'pressure': 'hPa', 'light': 'lux'}[sensor_type],
        'status': random.choice(['normal', 'warning', 'critical']) if random.random() < 0.1 else 'normal'
    }

def generate_transaction_data():
    """Generate random financial transaction data"""
    transaction_types = ['credit', 'debit', 'transfer', 'payment']
    merchants = ['Amazon', 'Walmart', 'Target', 'Starbucks', 'Shell', 'McDonald\'s']
    
    return {
        'id': str(uuid.uuid4()),
        'timestamp': datetime.now().isoformat(),
        'account_id': f"ACC_{random.randint(1000, 9999)}",
        'transaction_type': random.choice(transaction_types),
        'amount': round(random.uniform(5.0, 500.0), 2),
        'merchant': random.choice(merchants),
        'category': random.choice(['food', 'gas', 'shopping', 'entertainment', 'utilities']),
        'location': {
            'city': random.choice(['New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix']),
            'country': 'USA'
        },
        'is_fraud': random.random() < 0.02  # 2% chance of fraud
    }

# Data generators mapping
DATA_GENERATORS = {
    'user_activity': generate_user_activity,
    'sensor_data': generate_sensor_data,
    'transactions': generate_transaction_data
}

@app.route('/stream/<data_type>')
def stream_data(data_type):
    """Stream JSON data continuously"""
    if data_type not in DATA_GENERATORS:
        return jsonify({'error': f'Invalid data type. Available types: {list(DATA_GENERATORS.keys())}'}), 400
    
    def generate():
        generator_func = DATA_GENERATORS[data_type]
        while True:
            try:
                data = generator_func()
                yield f"data: {json.dumps(data)}\n\n"
                # Random delay between 2-4 seconds
                time.sleep(random.uniform(2.0, 4.0))
            except GeneratorExit:
                break
            except Exception as e:
                yield f"data: {json.dumps({'error': str(e)})}\n\n"
                time.sleep(2)
    
    return Response(
        generate(),
        mimetype='text/plain',
        headers={
            'Cache-Control': 'no-cache',
            'Connection': 'keep-alive',
            'Access-Control-Allow-Origin': '*'
        }
    )

@app.route('/stream/<data_type>/json')
def stream_data_json(data_type):
    """Stream pure JSON data (one JSON object per line)"""
    if data_type not in DATA_GENERATORS:
        return jsonify({'error': f'Invalid data type. Available types: {list(DATA_GENERATORS.keys())}'}), 400
    
    def generate():
        generator_func = DATA_GENERATORS[data_type]
        while True:
            try:
                data = generator_func()
                yield f"{json.dumps(data)}\n"
                # Random delay between 2-4 seconds
                time.sleep(random.uniform(2.0, 4.0))
            except GeneratorExit:
                break
            except Exception as e:
                yield f"{json.dumps({'error': str(e)})}\n"
                time.sleep(2)
    
    return Response(
        generate(),
        mimetype='application/json',
        headers={
            'Cache-Control': 'no-cache',
            'Connection': 'keep-alive',
            'Access-Control-Allow-Origin': '*'
        }
    )

@app.route('/api/single/<data_type>')
def get_single_record(data_type):
    """Get a single JSON record (for testing)"""
    if data_type not in DATA_GENERATORS:
        return jsonify({'error': f'Invalid data type. Available types: {list(DATA_GENERATORS.keys())}'}), 400
    
    generator_func = DATA_GENERATORS[data_type]
    return jsonify(generator_func())

@app.route('/api/batch/<data_type>/<int:count>')
def get_batch_records(data_type, count):
    """Get multiple JSON records at once"""
    if data_type not in DATA_GENERATORS:
        return jsonify({'error': f'Invalid data type. Available types: {list(DATA_GENERATORS.keys())}'}), 400
    
    if count > 100:
        return jsonify({'error': 'Maximum batch size is 100'}), 400
    
    generator_func = DATA_GENERATORS[data_type]
    records = [generator_func() for _ in range(count)]
    return jsonify({'records': records, 'count': len(records)})

@app.route('/')
def index():
    """API documentation"""
    return jsonify({
        'message': 'Simple Streaming JSON API for Spark Streaming',
        'endpoints': {
            '/stream/<data_type>': 'Continuous streaming with Server-Sent Events format',
            '/stream/<data_type>/json': 'Continuous streaming with pure JSON (one per line)',
            '/api/single/<data_type>': 'Get a single JSON record',
            '/api/batch/<data_type>/<count>': 'Get multiple records at once (max 100)'
        },
        'available_data_types': list(DATA_GENERATORS.keys()),
        'examples': {
            'streaming': 'http://localhost:5000/stream/user_activity/json',
            'single': 'http://localhost:5000/api/single/sensor_data',
            'batch': 'http://localhost:5000/api/batch/transactions/10'
        },
        'usage_notes': [
            'Data is generated every 2-4 seconds randomly',
            'Use /stream/<type>/json endpoint for Spark Streaming',
            'Press Ctrl+C to stop the streaming',
            'Each data type has different schema and fields'
        ]
    })

if __name__ == '__main__':
    print("Starting Simple Streaming JSON API...")
    print("Available endpoints:")
    print("- http://localhost:5000/ (documentation)")
    print("- http://localhost:5000/stream/user_activity/json")
    print("- http://localhost:5000/stream/sensor_data/json") 
    print("- http://localhost:5000/stream/transactions/json")
    print("\nPress Ctrl+C to stop the server")
    
    app.run(host='0.0.0.0', port=5000, debug=True, threaded=True)
