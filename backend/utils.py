import sqlite3
import qrcode
import io
import base64
import re

def init_db():
    """Initialize the database with required tables."""
    conn = sqlite3.connect('inventory.db')
    cursor = conn.cursor()
    
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
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
            FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
    ''')
    
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            product_id INTEGER NOT NULL,
            user_id INTEGER NOT NULL,
            status TEXT DEFAULT 'received' CHECK (status IN ('received', 'dispatched')),
            barcode TEXT UNIQUE NOT NULL,
            received_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            dispatched_at TIMESTAMP,
            FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE,
            FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
    ''')
    
    # Create indexes for better performance
    cursor.execute('CREATE INDEX IF NOT EXISTS idx_products_user_id ON products (user_id)')
    cursor.execute('CREATE INDEX IF NOT EXISTS idx_items_user_id ON items (user_id)')
    cursor.execute('CREATE INDEX IF NOT EXISTS idx_items_product_id ON items (product_id)')
    cursor.execute('CREATE INDEX IF NOT EXISTS idx_items_barcode ON items (barcode)')
    
    conn.commit()
    conn.close()

def get_db():
    """Get database connection with row factory."""
    conn = sqlite3.connect('inventory.db')
    conn.row_factory = sqlite3.Row
    return conn

def generate_barcode_data(user_id, product_id, item_id):
    """Generate barcode data string."""
    return f"{user_id}|{product_id}|{item_id}"

def parse_barcode_data(barcode_data):
    """Parse barcode data string into components."""
    try:
        parts = barcode_data.split('|')
        if len(parts) != 3:
            return None
        return {
            'user_id': int(parts[0]),
            'product_id': int(parts[1]),
            'item_id': parts[2]
        }
    except (ValueError, IndexError):
        return None

def generate_qr_code(data):
    """Generate QR code image as base64 string."""
    qr = qrcode.QRCode(version=1, box_size=10, border=5)
    qr.add_data(data)
    qr.make(fit=True)
    
    img = qr.make_image(fill_color="black", back_color="white")
    img_buffer = io.BytesIO()
    img.save(img_buffer, format='PNG')
    img_buffer.seek(0)
    
    return base64.b64encode(img_buffer.getvalue()).decode()

def validate_email(email):
    """Validate email format."""
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return re.match(pattern, email) is not None

def validate_password(password):
    """Validate password strength."""
    if len(password) < 8:
        return False, "Password must be at least 8 characters long"
    if not re.search(r'[A-Z]', password):
        return False, "Password must contain at least one uppercase letter"
    if not re.search(r'[a-z]', password):
        return False, "Password must contain at least one lowercase letter"
    if not re.search(r'\d', password):
        return False, "Password must contain at least one digit"
    return True, "Valid password"
