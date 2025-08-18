# app.py
from flask import Flask, request, jsonify
from flask_jwt_extended import JWTManager, jwt_required, create_access_token, get_jwt_identity
from werkzeug.security import generate_password_hash, check_password_hash
from werkzeug.utils import secure_filename
import sqlite3
import uuid
import os
from datetime import datetime, timedelta
import qrcode
import io
import base64

from dotenv import load_dotenv
import os

load_dotenv()

# Replace the hardcoded JWT key with:

app = Flask(__name__)
app.config['JWT_SECRET_KEY'] = os.getenv('JWT_SECRET_KEY', 'fallback-key-for-dev')

app.config['JWT_ACCESS_TOKEN_EXPIRES'] = timedelta(hours=24)
app.config['UPLOAD_FOLDER'] = 'uploads'

jwt = JWTManager(app)

@app.route('/')
def home():
    return jsonify({'message': 'Inventory API is running', 'version': '1.0'})
# Ensure upload directory exists
os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)

# Database initialization
def init_db():
    conn = sqlite3.connect('inventory.db')
    cursor = conn.cursor()
    
    # Users table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # Products table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            description TEXT,
            image_path TEXT,
            quantity INTEGER DEFAULT 0,
            threshold INTEGER DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users (id)
        )
    ''')
    
    # Items table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            product_id INTEGER NOT NULL,
            user_id INTEGER NOT NULL,
            status TEXT DEFAULT 'received',
            barcode TEXT UNIQUE NOT NULL,
            received_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            dispatched_at TIMESTAMP,
            FOREIGN KEY (product_id) REFERENCES products (id),
            FOREIGN KEY (user_id) REFERENCES users (id)
        )
    ''')
    
    conn.commit()
    conn.close()

def get_db():
    conn = sqlite3.connect('inventory.db')
    conn.row_factory = sqlite3.Row
    return conn

def generate_barcode_data(user_id, product_id, item_id):
    return f"{user_id}|{product_id}|{item_id}"

def parse_barcode_data(barcode_data):
    try:
        parts = barcode_data.split('|')
        if len(parts) != 3:
            return None
        return {
            'user_id': int(parts[0]),
            'product_id': int(parts[1]),
            'item_id': int(parts[2])
        }
    except:
        return None

def generate_qr_code(data):
    qr = qrcode.QRCode(version=1, box_size=10, border=5)
    qr.add_data(data)
    qr.make(fit=True)
    
    img = qr.make_image(fill_color="black", back_color="white")
    img_buffer = io.BytesIO()
    img.save(img_buffer, format='PNG')
    img_buffer.seek(0)
    
    return base64.b64encode(img_buffer.getvalue()).decode()

# Auth Routes
@app.route('/api/auth/register', methods=['POST'])
def register():
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')
    
    if not email or not password:
        return jsonify({'message': 'Email and password required'}), 400
    
    conn = get_db()
    cursor = conn.cursor()
    
    # Check if user already exists
    cursor.execute('SELECT id FROM users WHERE email = ?', (email,))
    if cursor.fetchone():
        conn.close()
        return jsonify({'message': 'User already exists'}), 409
    
    # Create new user
    password_hash = generate_password_hash(password)
    cursor.execute('INSERT INTO users (email, password_hash) VALUES (?, ?)', 
                   (email, password_hash))
    user_id = cursor.lastrowid
    conn.commit()
    conn.close()
    
    # Fix: Cast user_id to a string
    access_token = create_access_token(identity=str(user_id))
    return jsonify({
        'access_token': access_token,
        'user': {'id': user_id, 'email': email}
    }), 201

@app.route('/api/auth/login', methods=['POST'])
def login():
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')
    
    if not email or not password:
        return jsonify({'message': 'Email and password required'}), 400
    
    conn = get_db()
    cursor = conn.cursor()
    
    cursor.execute('SELECT id, email, password_hash FROM users WHERE email = ?', (email,))
    user = cursor.fetchone()
    conn.close()
    
    if not user or not check_password_hash(user['password_hash'], password):
        return jsonify({'message': 'Invalid credentials'}), 401
    
    # Fix: Cast user['id'] to a string
    access_token = create_access_token(identity=str(user['id']))
    return jsonify({
        'access_token': access_token,
        'user': {'id': user['id'], 'email': user['email']}
    }), 200
@app.route('/api/products', methods=['GET'])
@jwt_required()
def get_products():
    user_id = int(get_jwt_identity())  # ✅ Convert to int
    conn = get_db()
    cursor = conn.cursor()
    
    cursor.execute('''
        SELECT id, name, description, image_path, quantity, threshold, created_at
        FROM products 
        WHERE user_id = ?
        ORDER BY created_at DESC
    ''', (user_id,))
    
    products = []
    for row in cursor.fetchall():
        products.append({
            'id': row['id'],
            'name': row['name'],
            'description': row['description'],
            'image_path': row['image_path'],
            'quantity': row['quantity'],
            'threshold': row['threshold'],
            'created_at': row['created_at'],
            'is_low_stock': row['quantity'] < row['threshold'] if row['threshold'] > 0 else False
        })
    
    conn.close()
    return jsonify({'products': products}), 200
# Fixed receive_item function
@app.route('/api/products/<int:product_id>/receive', methods=['POST'])
@jwt_required()
def receive_item(product_id):  # ✅ Accept product_id as parameter
    user_id = int(get_jwt_identity())  # ✅ Convert to int for DB queries
    
    conn = get_db()
    cursor = conn.cursor()
    
    # Verify product belongs to user
    cursor.execute('SELECT id, name FROM products WHERE id = ? AND user_id = ?', 
                   (product_id, user_id))
    product = cursor.fetchone()
    
    if not product:
        conn.close()
        return jsonify({'message': 'Product not found'}), 404
    
    # Generate unique item ID
    item_uuid = str(uuid.uuid4())
    barcode_data = generate_barcode_data(user_id, product_id, item_uuid)
    
    # Create item record
    cursor.execute('''
        INSERT INTO items (product_id, user_id, barcode, status)
        VALUES (?, ?, ?, 'received')
    ''', (product_id, user_id, barcode_data))
    
    item_id = cursor.lastrowid
    
    # Update product quantity
    cursor.execute('UPDATE products SET quantity = quantity + 1 WHERE id = ?', (product_id,))
    
    # Get updated quantity
    cursor.execute('SELECT quantity FROM products WHERE id = ?', (product_id,))
    new_quantity = cursor.fetchone()['quantity']
    
    conn.commit()
    conn.close()
    
    # Generate QR code image
    qr_image = generate_qr_code(barcode_data)
    
    return jsonify({
        'item_id': item_id,
        'barcode_data': barcode_data,
        'qr_image': qr_image,
        'product_name': product['name'],
        'new_quantity': new_quantity
    }), 201

@app.route('/api/items/dispatch', methods=['POST'])
@jwt_required()
def dispatch_item():
    user_id = int(get_jwt_identity())  # ✅ Convert to int
    data = request.get_json()
    barcode_data = data.get('barcode_data')
    
    if not barcode_data:
        return jsonify({'message': 'Barcode data required'}), 400
    
    # Parse barcode
    parsed = parse_barcode_data(barcode_data)
    if not parsed or parsed['user_id'] != user_id:
        return jsonify({'message': 'Invalid barcode'}), 400
    
    conn = get_db()
    cursor = conn.cursor()
    
    # Find the item
    cursor.execute('''
        SELECT i.id, i.status, p.name as product_name, p.id as product_id
        FROM items i
        JOIN products p ON i.product_id = p.id
        WHERE i.barcode = ? AND i.user_id = ?
    ''', (barcode_data, user_id))
    
    item = cursor.fetchone()
    
    if not item:
        conn.close()
        return jsonify({'message': 'Item not found'}), 404
    
    if item['status'] == 'dispatched':
        conn.close()
        return jsonify({'message': 'Item already dispatched'}), 409
    
    # Mark as dispatched
    cursor.execute('''
        UPDATE items 
        SET status = 'dispatched', dispatched_at = CURRENT_TIMESTAMP
        WHERE id = ?
    ''', (item['id'],))
    
    # Update product quantity
    cursor.execute('UPDATE products SET quantity = quantity - 1 WHERE id = ?', 
                   (item['product_id'],))
    
    # Get updated quantity
    cursor.execute('SELECT quantity FROM products WHERE id = ?', (item['product_id'],))
    new_quantity = cursor.fetchone()['quantity']
    
    conn.commit()
    conn.close()
    
    return jsonify({
        'message': 'Item dispatched successfully',
        'product_name': item['product_name'],
        'new_quantity': new_quantity
    }), 200

@app.route('/api/dashboard/alerts', methods=['GET'])
@jwt_required()
def get_alerts():
    user_id = get_jwt_identity()
    conn = get_db()
    cursor = conn.cursor()
    
    cursor.execute('''
        SELECT id, name, quantity, threshold
        FROM products 
        WHERE user_id = ? AND threshold > 0 AND quantity < threshold
        ORDER BY quantity ASC
    ''', (user_id,))
    
    alerts = []
    for row in cursor.fetchall():
        alerts.append({
            'product_id': row['id'],
            'product_name': row['name'],
            'current_quantity': row['quantity'],
            'threshold': row['threshold']
        })
    
    conn.close()
    return jsonify({'alerts': alerts}), 200

if __name__ == '__main__':
    init_db()
    app.run(debug=True, host='0.0.0.0', port=5000)