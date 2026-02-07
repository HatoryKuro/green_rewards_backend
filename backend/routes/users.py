from flask import Blueprint, request, jsonify  # Đảm bảo có jsonify
from models.database import users, check_database
from utils.helpers import safe_int, json_error
from bson.objectid import ObjectId
from datetime import datetime

users_bp = Blueprint('users', __name__)

@users_bp.route("/users", methods=["GET"])
def get_all_users():
    # Kiểm tra database
    if not check_database():
        return json_error("Database không khả dụng", 503)
    
    try:
        # Lấy tất cả user (bao gồm cả admin và manager)
        users_list = users.find().sort("created_at", -1)
        
        result = []
        for user in users_list:
            role = user.get("role", "user")
            isAdmin = role == "admin"
            isManager = role in ["admin", "manager"]
            
            result.append({
                "_id": str(user["_id"]),
                "id": str(user["_id"]),
                "username": user["username"],
                "email": user["email"],
                "phone": user["phone"],
                "role": role,
                "isAdmin": isAdmin,
                "isManager": isManager,
                "point": safe_int(user.get("point", 0)),
                "created_at": user.get("created_at", datetime.now()).isoformat()
            })
        
        return jsonify(result), 200
    except Exception as e:
        return json_error(f"Lỗi database: {str(e)}", 500)

@users_bp.route("/users/<user_id>/role", methods=["PUT"])
def update_user_role(user_id):
    # Kiểm tra database
    if not check_database():
        return json_error("Database không khả dụng", 503)
    
    try:
        data = request.json
        new_role = data.get("role")
        
        # Kiểm tra role hợp lệ
        if not new_role or new_role not in ["user", "manager", "admin"]:
            return json_error("Role không hợp lệ. Chọn user, manager hoặc admin", 400)
        
        # Tìm user cần cập nhật
        user = users.find_one({"_id": ObjectId(user_id)})
        if not user:
            return json_error("User không tồn tại", 404)
        
        current_role = user.get("role", "user")
        
        # Không cho phép thay đổi role của admin khác (chỉ admin có thể thay đổi)
        if current_role == "admin" and new_role != "admin":
            return json_error("Không thể thay đổi role của admin", 400)
        
        # Cập nhật role
        isAdmin = new_role == "admin"
        isManager = new_role in ["admin", "manager"]
        
        update_data = {
            "role": new_role,
            "isAdmin": isAdmin,
            "isManager": isManager
        }
        
        result = users.update_one(
            {"_id": ObjectId(user_id)},
            {"$set": update_data}
        )
        
        if result.modified_count == 1:
            return jsonify({
                "message": f"Cập nhật role thành công thành {new_role}",
                "new_role": new_role,
                "isAdmin": isAdmin,
                "isManager": isManager
            }), 200
        else:
            return json_error("Cập nhật thất bại hoặc không có thay đổi", 400)
            
    except Exception as e:
        return json_error(f"Lỗi: {str(e)}", 500)

@users_bp.route("/users/<user_id>", methods=["DELETE"])
def delete_user(user_id):
    # Kiểm tra database
    if not check_database():
        return json_error("Database không khả dụng", 503)
    
    try:
        # Tìm user cần xóa
        user = users.find_one({"_id": ObjectId(user_id)})
        if not user:
            return json_error("User không tồn tại", 404)
        
        # Không cho xóa admin
        if user.get("role") == "admin":
            return json_error("Không thể xóa tài khoản admin", 400)
        
        result = users.delete_one({"_id": ObjectId(user_id)})
        if result.deleted_count == 1:
            return jsonify({"message": "Xóa user thành công"}), 200
        else:
            return json_error("User không tồn tại", 404)
    except Exception as e:
        return json_error(f"Lỗi: {str(e)}", 500)

@users_bp.route("/users/<user_id>/reset-point", methods=["PUT"])
def reset_user_point(user_id):
    # Kiểm tra database
    if not check_database():
        return json_error("Database không khả dụng", 503)
    
    try:
        # Kiểm tra user có tồn tại không
        user = users.find_one({"_id": ObjectId(user_id)})
        if not user:
            return json_error("User không tồn tại", 404)
        
        # Không cho reset điểm của admin
        if user.get("role") == "admin":
            return json_error("Không thể reset điểm của admin", 400)
        
        # Lấy điểm hiện tại
        current_point = user.get("point", 0)
        
        # Nếu điểm đã là 0 thì không cần reset
        if current_point <= 0:
            return json_error("Người dùng này không có điểm để reset", 400)
        
        # Lấy thông tin từ request: ai reset và lý do
        data = request.json or {}
        reset_by = data.get("reset_by", "system")  # Mặc định là system nếu không có
        reason = data.get("reason", "Hệ thống lỗi nên điểm trả về 0")
        
        # Tạo entry lịch sử
        history_entry = {
            "date": datetime.now().isoformat(),
            "type": "reset",
            "point": -current_point,  # Số điểm bị trừ đi (số âm)
            "message": reason,
            "reset_by": reset_by,
            "old_point": current_point,
            "new_point": 0
        }
        
        # Cập nhật điểm về 0 và thêm vào lịch sử
        result = users.update_one(
            {"_id": ObjectId(user_id)},
            {
                "$set": {"point": 0},
                "$push": {"history": history_entry}
            }
        )
        
        if result.modified_count == 1:
            return jsonify({
                "message": "Reset điểm thành công",
                "old_point": current_point,
                "new_point": 0,
                "history_added": True
            }), 200
        else:
            return json_error("User không tồn tại hoặc không có thay đổi", 404)
    except Exception as e:
        return json_error(f"Lỗi: {str(e)}", 500)

@users_bp.route("/users/<username>", methods=["GET"])
def get_user_by_username(username):
    # Kiểm tra database
    if not check_database():
        return json_error("Database không khả dụng", 503)
    
    try:
        user = users.find_one({"username": username})
        if not user:
            return json_error("User không tồn tại", 404)
        
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
            "point": safe_int(user.get("point", 0)),
            "history": user.get("history", []),
            "usedBills": user.get("usedBills", [])
        }), 200
    except Exception as e:
        return json_error(f"Lỗi: {str(e)}", 500)