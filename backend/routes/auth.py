from flask import Blueprint, request, jsonify
from models.database import users, check_database
from utils.helpers import hash_password, safe_int, json_error
from datetime import datetime

auth_bp = Blueprint('auth', __name__)

@auth_bp.route("/login", methods=["POST"])
def login():
    # Kiểm tra database
    if not check_database():
        return json_error("Database không khả dụng", 503)
    
    data = request.json
    if not data:
        return json_error("Không có dữ liệu", 400)
    
    # NHẬN CẢ 'identifier' VÀ 'username' (tương thích cả 2)
    identity = data.get("identifier") or data.get("username")
    password = data.get("password")

    if not identity or not password:
        return json_error("Vui lòng điền đầy đủ thông tin", 400)

    user = users.find_one({
        "$or": [
            {"username": identity},
            {"email": identity},
            {"phone": identity}
        ]
    })

    if not user or user["password"] != hash_password(password):
        return json_error("Sai tài khoản hoặc mật khẩu", 401)

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
    # Kiểm tra database
    if not check_database():
        return json_error("Database không khả dụng", 503)
    
    data = request.json
    if not data:
        return json_error("Không có dữ liệu", 400)
    
    # Kiểm tra required fields
    required_fields = ["username", "email", "phone", "password"]
    for field in required_fields:
        if not data.get(field):
            return json_error(f"Thiếu trường {field}", 400)
    
    # Kiểm tra trùng username
    if users.find_one({"username": data["username"]}):
        return json_error("Tên đăng nhập đã tồn tại", 400)
    
    # Kiểm tra trùng email
    if users.find_one({"email": data["email"]}):
        return json_error("Email đã tồn tại", 400)
    
    # Kiểm tra trùng số điện thoại
    if users.find_one({"phone": data["phone"]}):
        return json_error("Số điện thoại đã tồn tại", 400)
    
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
        return json_error(f"Lỗi database: {str(e)}", 500)