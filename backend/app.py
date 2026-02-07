from flask import Flask, jsonify
from flask_cors import CORS
from database import users
from utils.helpers import hash_password
from datetime import datetime
import os

# Import các blueprint
from routes.auth import auth_bp
from routes.users import users_bp
from routes.vouchers import vouchers_bp
from routes.partners import partners_bp
from routes.scan import scan_bp
from routes.images import images_bp

app = Flask(__name__)
CORS(app)

# Đăng ký blueprint
app.register_blueprint(auth_bp)
app.register_blueprint(users_bp)
app.register_blueprint(vouchers_bp)
app.register_blueprint(partners_bp)
app.register_blueprint(scan_bp)
app.register_blueprint(images_bp)

# =========================
# TẠO ADMIN & MANAGER MẶC ĐỊNH
# =========================
def create_default_users():
    try:
        if users is not None:
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

# =========================
# HEALTH CHECK ENDPOINT
# =========================
@app.route("/health", methods=["GET"])
def health_check():
    from utils.db_check import check_database
    db_status = check_database()
    
    return jsonify({
        "status": "ok" if db_status else "error",
        "database": "connected" if db_status else "disconnected",
        "message": "Service is running" if db_status else "Database connection failed"
    }), 200 if db_status else 503

# Tạo user mặc định khi khởi động
create_default_users()

if __name__ == "__main__":
    port = int(os.getenv("PORT", 10000))
    app.run(host="0.0.0.0", port=port, debug=False)