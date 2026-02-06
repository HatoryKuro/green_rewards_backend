# backend/app.py
from flask import Flask, jsonify
from flask_cors import CORS
from database import users
from utils import hash_password
from datetime import datetime
import os

app = Flask(__name__)
CORS(app)

# Import các route từ thư mục routes
from routes.auth import auth_bp
from routes.users import user_bp
from routes.vouchers import voucher_bp
from routes.partners import partner_bp
from routes.scan import scan_bp
from routes.images import image_bp

# Đăng ký các blueprint
app.register_blueprint(auth_bp)
app.register_blueprint(user_bp)
app.register_blueprint(voucher_bp)
app.register_blueprint(partner_bp)
app.register_blueprint(scan_bp)
app.register_blueprint(image_bp)

# =========================
# ENSURE ADMIN & MANAGER
# =========================
def check_database():
    return users is not None

if check_database():
    try:
        # Tạo admin nếu chưa có
        admin = users.find_one({"username": "admin"})
        if not admin:
            users.insert_one({
                "username": "admin",
                "email": "admin@system.com",
                "phone": "0000000000",
                "password": hash_password("admin1"),
                "role": "admin",
                "isAdmin": True,
                "isManager": True,
                "point": 0,
                "usedBills": [],
                "history": [],
                "created_at": datetime.now()
            })
            print("✓ Đã tạo tài khoản admin mặc định")
        
        # Tạo manager nếu chưa có
        manager = users.find_one({"username": "manager"})
        if not manager:
            users.insert_one({
                "username": "manager",
                "email": "manager@system.com",
                "phone": "1111111111",
                "password": hash_password("manager1"),
                "role": "manager",
                "isAdmin": False,
                "isManager": True,
                "point": 0,
                "usedBills": [],
                "history": [],
                "created_at": datetime.now()
            })
            print("✓ Đã tạo tài khoản manager mặc định")
    except Exception as e:
        print(f"⚠ Không thể tạo user mặc định: {e}")

# =========================
# HEALTH CHECK
# =========================
@app.route("/health", methods=["GET"])
def health_check():
    return jsonify({
        "status": "ok" if check_database() else "error",
        "database": "connected" if check_database() else "disconnected",
        "message": "Service is running" if check_database() else "Database connection failed"
    }), 200 if check_database() else 503

if __name__ == "__main__":
    port = int(os.getenv("PORT", 10000))
    app.run(host="0.0.0.0", port=port, debug=False)