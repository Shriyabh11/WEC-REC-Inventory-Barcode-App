from flask import Flask, jsonify, send_from_directory
from flask_jwt_extended import JWTManager
from datetime import timedelta
import os
from dotenv import load_dotenv
from utils import init_db
from routes.auth_routes import auth_bp
from routes.product_routes import products_bp

load_dotenv()

app = Flask(__name__, static_folder='static')
app.config['JWT_SECRET_KEY'] = os.getenv('JWT_SECRET_KEY', 'fallback-key-for-dev')
app.config['JWT_ACCESS_TOKEN_EXPIRES'] = timedelta(hours=24)
app.config['UPLOAD_FOLDER'] = 'uploads'

jwt = JWTManager(app)

os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)

@app.route('/')
def home():
    return jsonify({'message': 'Inventory API is running', 'version': '1.0'})

@app.errorhandler(404)
def not_found(error):
    return jsonify({'message': 'Endpoint not found'}), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({'message': 'Internal server error'}), 500

@app.route('/static/product_images/<filename>')
def serve_product_image(filename):
    return send_from_directory('static/product_images', filename)

# Register blueprints
app.register_blueprint(auth_bp)
app.register_blueprint(products_bp)

if __name__ == '__main__':
    init_db()
    app.run(debug=True, host='0.0.0.0', port=5000)