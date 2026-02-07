from flask import Flask, jsonify  # Thêm jsonify vào đây
from flask_cors import CORS
import os

# Import routes
from routes.auth import auth_bp
from routes.users import users_bp
from routes.vouchers import vouchers_bp
from routes.partners import partners_bp
from routes.scan import scan_bp
from routes.images import images_bp

# Import database và utils
from models.database import users, check_database
from utils.helpers import hash_password, safe_int
from datetime import datetime

app = Flask(__name__)
CORS(app)

# =========================
# REGISTER BLUEPRINTS
# =========================
app.register_blueprint(auth_bp)
app.register_blueprint(users_bp)
app.register_blueprint(vouchers_bp)
app.register_blueprint(partners_bp)
app.register_blueprint(scan_bp)
app.register_blueprint(images_bp)

# =========================
# ROOT ENDPOINT (optional)
# =========================
@app.route("/", methods=["GET"])
def home():
    return jsonify({
        "message": "Green Rewards API is running",
        "endpoints": {
            "health": "/health (GET)",
            "auth": {
                "login": "/login (POST)",
                "register": "/register (POST)"
            },
            "users": {
                "get_all_users": "/users (GET)",
                "get_user": "/users/<username> (GET)"
            },
            "vouchers": {
                "get_vouchers": "/vouchers (GET)",
                "get_user_vouchers": "/users/<username>/vouchers (GET)"
            }
        }
    })

# =========================
# HEALTH CHECK ENDPOINT
# =========================
@app.route("/health", methods=["GET"])
def health_check():
    return jsonify({
        "status": "ok" if check_database() else "error",
        "database": "connected" if check_database() else "disconnected",
        "message": "Service is running" if check_database() else "Database connection failed"
    }), 200 if check_database() else 503

# =========================
# ENSURE ADMIN & MANAGER (với kiểm tra database)
# =========================
if check_database():
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

if __name__ == "__main__":
    port = int(os.getenv("PORT", 10000))
    app.run(host="0.0.0.0", port=port, debug=False)