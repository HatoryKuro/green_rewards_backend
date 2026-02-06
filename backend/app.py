# backend/app.py
from flask import Flask, jsonify
from flask_cors import CORS
import os
import sys

# Thêm thư mục hiện tại vào path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

app = Flask(__name__)
CORS(app)

# Import routes
from routes import auth, users, vouchers, partners, scan, images

# Đăng ký blueprints
app.register_blueprint(auth.auth_bp)
app.register_blueprint(users.user_bp)
app.register_blueprint(vouchers.voucher_bp)
app.register_blueprint(partners.partner_bp)
app.register_blueprint(scan.scan_bp)
app.register_blueprint(images.image_bp)

# ... phần còn lại của code