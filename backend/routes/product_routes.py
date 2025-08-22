import sqlite3
import uuid
import os
from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required, get_jwt_identity
from werkzeug.utils import secure_filename
from utils import generate_barcode_data, get_db, parse_barcode_data, generate_qr_code

products_bp = Blueprint('products_bp', __name__)

UPLOAD_FOLDER = 'static/product_images'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif'}

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@products_bp.route('/api/products', methods=['GET'])
@jwt_required()
def get_products():
    try:
        print("get_products called")
        user_id = int(get_jwt_identity())
        print(f"user_id: {user_id}")
        conn = get_db()
        cursor = conn.cursor()

        # Fetch all products for the user
        cursor.execute('''
            SELECT id, name, description, image_path, quantity, threshold, created_at
            FROM products
            WHERE user_id = ?
        ''', (user_id,))
        product_rows = cursor.fetchall()
        print(f"Fetched {len(product_rows)} products")

        # Fetch all items for the user
        cursor.execute('''
            SELECT id, product_id, barcode, status
            FROM items
            WHERE user_id = ?
        ''', (user_id,))
        item_rows = cursor.fetchall()
        print(f"Fetched {len(item_rows)} items")

        conn.close()

        # Organize items by product_id for fast lookup
        items_by_product = {}
        for item_row in item_rows:
            product_id = item_row['product_id']
            if product_id not in items_by_product:
                items_by_product[product_id] = []
            items_by_product[product_id].append({
                'id': item_row['id'],
                'barcode': item_row['barcode'],
                'status': item_row['status'],
                #'created_at': item_row['created_at']
            })

        products_list = []
        for product_row in product_rows:
            is_low_stock = product_row['quantity'] < product_row['threshold'] if product_row['threshold'] > 0 else False

            product_data = {
                'id': product_row['id'],
                'name': product_row['name'],
                'description': product_row['description'],
                'image_path': product_row['image_path'],
                'quantity': product_row['quantity'],
                'threshold': product_row['threshold'],
                #'created_at': product_row['created_at'],
                'is_low_stock': is_low_stock,
                'items': items_by_product.get(product_row['id'], [])
            }
            products_list.append(product_data)

        print("Returning products:", products_list)
        return jsonify({'products': products_list}), 200

    except sqlite3.Error as e:
        print(f"Database error: {e}")
        return jsonify({'message': f'Database error: {str(e)}'}), 500
    except Exception as e:
        print(f"Server error: {e}")
        return jsonify({'message': f'Server error: {str(e)}'}), 500
@products_bp.route('/api/products/create', methods=['POST'])
@jwt_required()
def create_product():
    try:
        user_id = int(get_jwt_identity())
        # Accept both JSON and multipart/form-data
        if request.content_type.startswith('multipart/form-data'):
            name = request.form.get('name', '').strip()
            description = request.form.get('description', '').strip()
            threshold = request.form.get('threshold', 0)
            file = request.files.get('image')
        else:
            data = request.get_json()
            name = data.get('name', '').strip()
            description = data.get('description', '').strip()
            threshold = data.get('threshold', 0)
            file = None

        if not name:
            return jsonify({'message': 'Product name is required'}), 400

        if len(name) > 255:
            return jsonify({'message': 'Product name too long (max 255 characters)'}), 400

        try:
            threshold = int(threshold) if threshold is not None else 0
            if threshold < 0:
                return jsonify({'message': 'Threshold cannot be negative'}), 400
        except (ValueError, TypeError):
            return jsonify({'message': 'Invalid threshold value'}), 400

        image_path = None
        if file and allowed_file(file.filename):
            os.makedirs(UPLOAD_FOLDER, exist_ok=True)
            filename = secure_filename(file.filename)
            save_path = os.path.join(UPLOAD_FOLDER, filename)
            file.save(save_path)
            image_path = save_path

        conn = get_db()
        cursor = conn.cursor()

        # Check if product name already exists for this user
        cursor.execute('SELECT id FROM products WHERE user_id = ? AND name = ?', (user_id, name))
        if cursor.fetchone():
            conn.close()
            return jsonify({'message': 'Product with this name already exists'}), 409

        cursor.execute(
            'INSERT INTO products (user_id, name, description, threshold, image_path) VALUES (?, ?, ?, ?, ?)',
            (user_id, name, description, threshold, image_path)
        )
        conn.commit()
        product_id = cursor.lastrowid

        # Fetch the complete product data to return
        cursor.execute('''
            SELECT id, name, description, image_path, quantity, threshold, created_at
            FROM products 
            WHERE id = ?
        ''', (product_id,))
        product_row = cursor.fetchone()

        is_low_stock = product_row['quantity'] < product_row['threshold'] if product_row['threshold'] > 0 else False

        product = {
            'id': product_row['id'],
            'name': product_row['name'],
            'description': product_row['description'],
            'image_path': product_row['image_path'],
            'quantity': product_row['quantity'],
            'threshold': product_row['threshold'],
            'created_at': product_row['created_at'],
            'is_low_stock': is_low_stock,
            'items': []
        }

        conn.close()

        return jsonify({
            'message': 'Product created successfully',
            'product': product
        }), 201

    except sqlite3.Error as e:
        return jsonify({'message': f'Database error: {str(e)}'}), 500
    except Exception as e:
        return jsonify({'message': f'Server error: {str(e)}'}), 500

@products_bp.route('/api/products/<int:product_id>', methods=['GET'])
@jwt_required()
def get_product(product_id):
    try:
        user_id = int(get_jwt_identity())
        conn = get_db()
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT id, name, description, image_path, quantity, threshold, created_at
            FROM products 
            WHERE id = ? AND user_id = ?
        ''', (product_id, user_id))
        
        row = cursor.fetchone()
        if not row:
            conn.close()
            return jsonify({'message': 'Product not found'}), 404
        
        # Fetch all items for the product
        cursor.execute('''
            SELECT id, barcode, status, created_at
            FROM items
            WHERE product_id = ?
        ''', (product_id,))
        item_rows = cursor.fetchall()
        
        items_list = []
        for item_row in item_rows:
            items_list.append({
                'id': item_row['id'],
                'barcode': item_row['barcode'],
                'status': item_row['status'],
                'created_at': item_row['created_at']
            })

        product = {
            'id': row['id'],
            'name': row['name'],
            'description': row['description'],
            'image_path': row['image_path'],
            'quantity': row['quantity'],
            'threshold': row['threshold'],
            'created_at': row['created_at'],
            'is_low_stock': row['quantity'] < row['threshold'] if row['threshold'] > 0 else False,
            'items': items_list # ✨ Add the items list to the single product response ✨
        }
        
        conn.close()
        return jsonify({'product': product}), 200
        
    except sqlite3.Error as e:
        return jsonify({'message': f'Database error: {str(e)}'}), 500
    except Exception as e:
        return jsonify({'message': 'Failed to fetch product'}), 500

@products_bp.route('/api/products/<int:product_id>/receive', methods=['POST'])
@jwt_required()
def receive_item(product_id):
    try:
        user_id = int(get_jwt_identity())
        
        conn = get_db()
        cursor = conn.cursor()
        
        # Verify product exists and belongs to user
        cursor.execute('SELECT id, name FROM products WHERE id = ? AND user_id = ?', 
                      (product_id, user_id))
        product = cursor.fetchone()
        
        if not product:
            conn.close()
            return jsonify({'message': 'Product not found'}), 404
        
        # Generate unique item identifier and barcode
        item_uuid = str(uuid.uuid4())
        barcode_data = generate_barcode_data(user_id, product_id, item_uuid)
        
        # Insert new item
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
        
        # Generate QR code
        qr_image = generate_qr_code(barcode_data)
        
        return jsonify({
            'item_id': item_id,
            'barcode_data': barcode_data,
            'qr_image': qr_image,
            'product_name': product['name'],
            'new_quantity': new_quantity
        }), 201
        
    except sqlite3.Error as e:
        return jsonify({'message': f'Database error: {str(e)}'}), 500
    except Exception as e:
        return jsonify({'message': 'Failed to receive item'}), 500

@products_bp.route('/api/items/dispatch', methods=['POST'])
@jwt_required()
def dispatch_item():
    try:
        user_id = int(get_jwt_identity())
        data = request.get_json()
        
        if not data:
            return jsonify({'message': 'No data provided'}), 400
        
        barcode_data = data.get('barcode_data')
        
        if not barcode_data:
            return jsonify({'message': 'Barcode data required'}), 400
        
        # Parse and validate barcode
        parsed = parse_barcode_data(barcode_data)
        if not parsed or parsed['user_id'] != user_id:
            return jsonify({'message': 'Invalid barcode'}), 400
        
        conn = get_db()
        cursor = conn.cursor()
        
        # Find item
        cursor.execute('''
            SELECT i.id, i.status, p.name as product_name, p.id as product_id, p.quantity
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
        
        # Check if there's stock to dispatch
        if item['quantity'] <= 0:
            conn.close()
            return jsonify({'message': 'No stock available to dispatch'}), 400
        
        # Update item status
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
        
    except sqlite3.Error as e:
        return jsonify({'message': f'Database error: {str(e)}'}), 500
    except Exception as e:
        return jsonify({'message': 'Failed to dispatch item'}), 500

@products_bp.route('/api/dashboard/alerts', methods=['GET'])
@jwt_required()
def get_alerts():
    try:
        user_id = int(get_jwt_identity())
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
                'threshold': row['threshold'],
                'urgency': 'critical' if row['quantity'] == 0 else 'warning'
            })
        
        conn.close()
        return jsonify({'alerts': alerts}), 200
        
    except sqlite3.Error as e:
        return jsonify({'message': f'Database error: {str(e)}'}), 500
    except Exception as e:
        return jsonify({'message': 'Failed to fetch alerts'}), 500

@products_bp.route('/api/dashboard/stats', methods=['GET'])
@jwt_required()
def get_dashboard_stats():
    try:
        user_id = int(get_jwt_identity())
        conn = get_db()
        cursor = conn.cursor()
        
        # Total products
        cursor.execute('SELECT COUNT(*) as total FROM products WHERE user_id = ?', (user_id,))
        total_products = cursor.fetchone()['total']
        
        # Total items in stock
        cursor.execute('SELECT COALESCE(SUM(quantity), 0) as total FROM products WHERE user_id = ?', (user_id,))
        total_stock = cursor.fetchone()['total']
        
        # Low stock products
        cursor.execute('''
            SELECT COUNT(*) as count FROM products 
            WHERE user_id = ? AND threshold > 0 AND quantity < threshold
        ''', (user_id,))
        low_stock_count = cursor.fetchone()['count']
        
        # Out of stock products
        cursor.execute('SELECT COUNT(*) as count FROM products WHERE user_id = ? AND quantity = 0', (user_id,))
        out_of_stock_count = cursor.fetchone()['count']
        
        conn.close()
        
        return jsonify({
            'total_products': total_products,
            'total_stock': total_stock,
            'low_stock_count': low_stock_count,
            'out_of_stock_count': out_of_stock_count
        }), 200
        
    except sqlite3.Error as e:
        return jsonify({'message': f'Database error: {str(e)}'}), 500
    except Exception as e:
        return jsonify({'message': 'Failed to fetch dashboard stats'}), 500