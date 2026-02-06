from flask import Flask
from flask_cors import CORS
from database import users
from datetime import datetime
import hashlib
import os

# Import các Blueprint
from blueprints.auth import auth_bp
from blueprints.users import users_bp
from blueprints.vouchers import vouchers_bp
from blueprints.partners import partners_bp
from blueprints.images import images_bp
from blueprints.health import health_bp
from blueprints.qr import qr_bp

app = Flask(__name__)
CORS(app)

# Đăng ký các Blueprint
app.register_blueprint(auth_bp)
app.register_blueprint(users_bp)
app.register_blueprint(vouchers_bp)
app.register_blueprint(partners_bp)
app.register_blueprint(images_bp)
app.register_blueprint(health_bp)
app.register_blueprint(qr_bp)

# Hàm tiện ích
def hash_password(pw):
    return hashlib.sha256(pw.encode()).hexdigest()

# =========================
# INIT DEFAULT USERS (chỉ chạy một lần khi khởi động)
# =========================
def init_default_users():
    """Khởi tạo admin và manager mặc định"""
    try:
        # Kiểm tra và tạo admin nếu chưa có
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
        
        # Kiểm tra và tạo manager nếu chưa có
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

# Chạy khi khởi động app
if __name__ != "__main__":
    # Nếu chạy với WSGI server (production)
    with app.app_context():
        init_default_users()

if __name__ == "__main__":
    init_default_users()
    port = int(os.getenv("PORT", 10000))
    app.run(host="0.0.0.0", port=port, debug=False)