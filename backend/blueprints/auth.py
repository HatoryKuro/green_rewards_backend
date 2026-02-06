from flask import Blueprint, request, jsonify
from datetime import datetime
from database import users
from utils.helpers import hash_password, safe_int
from utils.validators import validate_user_exists, check_duplicate_user
from bson.objectid import ObjectId

auth_bp = Blueprint('auth', __name__)

@auth_bp.route("/login", methods=["POST"])
def login():
    data = request.json
    identity = data.get("username")
    password = data.get("password")

    user = users.find_one({
        "$or": [
            {"username": identity},
            {"email": identity},
            {"phone": identity}
        ]
    })

    if not user or user["password"] != hash_password(password):
        return jsonify({"error": "Sai tài khoản hoặc mật khẩu"}), 401

    # Xác định role và isManager dựa trên trường role
    role = user.get("role", "user")
    isAdmin = role == "admin"
    isManager = role in ["admin", "manager"]

    return jsonify({
        "_id": str(user["_id"]),
        "username": user["username"],
        "email": user["email"],
        "phone": user["phone"],
        "role": role,
        "isAdmin": isAdmin,
        "isManager": isManager,
        "point": safe_int(user.get("point", 0))
    }), 200

@auth_bp.route("/register", methods=["POST"])
def register():
    data = request.json
    
    # Kiểm tra required fields
    required_fields = ["username", "email", "phone", "password"]
    for field in required_fields:
        if not data.get(field):
            return jsonify({"error": f"Thiếu trường {field}"}), 400
    
    # Kiểm tra trùng username
    if users.find_one({"username": data["username"]}):
        return jsonify({"error": "Tên đăng nhập đã tồn tại"}), 400
    
    # Kiểm tra trùng email
    if users.find_one({"email": data["email"]}):
        return jsonify({"error": "Email đã tồn tại"}), 400
    
    # Kiểm tra trùng số điện thoại
    if users.find_one({"phone": data["phone"]}):
        return jsonify({"error": "Số điện thoại đã tồn tại"}), 400
    
    # Tạo user mới với role mặc định là "user"
    new_user = {
        "username": data["username"],
        "email": data["email"],
        "phone": data["phone"],
        "password": hash_password(data["password"]),
        "role": "user",
        "isAdmin": False,
        "isManager": False,
        "point": 0,
        "usedBills": [],
        "history": [],
        "created_at": datetime.now()
    }
    
    try:
        result = users.insert_one(new_user)
        return jsonify({
            "message": "Đăng ký thành công",
            "user_id": str(result.inserted_id)
        }), 200
    except Exception as e:
        return jsonify({"error": f"Lỗi database: {str(e)}"}), 500