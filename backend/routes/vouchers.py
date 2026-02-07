from flask import Blueprint, request, jsonify
from database import vouchers, user_vouchers, users
from bson.objectid import ObjectId
from datetime import datetime
from utils.helpers import safe_int

vouchers_bp = Blueprint('vouchers', __name__)

def check_database():
    return vouchers is not None and user_vouchers is not None and users is not None

@vouchers_bp.route("/admin/vouchers", methods=["POST"])
def create_voucher():
    # Kiểm tra database
    if not check_database():
        return jsonify({"error": "Database không khả dụng"}), 503
    
    data = request.json
    
    required_fields = ["partner", "point", "maxPerUser", "expired"]
    for field in required_fields:
        if not data.get(field):
            return jsonify({"error": f"Thiếu trường {field}"}), 400
    
    new_voucher = {
        "partner": data["partner"],
        "point": int(data["point"]),
        "maxPerUser": int(data["maxPerUser"]),
        "expired": data["expired"],
        "status": "available",
        "created_at": datetime.now()
    }
    
    try:
        result = vouchers.insert_one(new_voucher)
        return jsonify({
            "message": "Tạo voucher thành công",
            "voucher_id": str(result.inserted_id)
        }), 201
    except Exception as e:
        return jsonify({"error": f"Lỗi database: {str(e)}"}), 500

@vouchers_bp.route("/vouchers", methods=["GET"])
def get_available_vouchers():
    # Kiểm tra database
    if not check_database():
        return jsonify([]), 200  # Trả về mảng rỗng
    
    try:
        vouchers_list = vouchers.find({"status": "available"}).sort("point", 1)
        
        result = []
        for voucher in vouchers_list:
            result.append({
                "_id": str(voucher["_id"]),
                "partner": voucher["partner"],
                "point": voucher["point"],
                "maxPerUser": voucher["maxPerUser"],
                "expired": voucher["expired"],
                "status": voucher["status"]
            })
        
        return jsonify(result), 200
    except Exception as e:
        return jsonify({"error": f"Lỗi database: {str(e)}"}), 500

@vouchers_bp.route("/users/<username>/exchange-voucher", methods=["POST"])
def exchange_voucher(username):
    # Kiểm tra database
    if not check_database():
        return jsonify({"error": "Database không khả dụng"}), 503
    
    data = request.json
    voucher_id = data.get("voucher_id")
    
    if not voucher_id:
        return jsonify({"error": "Thiếu voucher_id"}), 400
    
    # Kiểm tra user
    user = users.find_one({"username": username})
    if not user:
        return jsonify({"error": "User không tồn tại"}), 404
    
    # Kiểm tra voucher
    voucher = vouchers.find_one({"_id": ObjectId(voucher_id)})
    if not voucher:
        return jsonify({"error": "Voucher không tồn tại"}), 404
    
    # Kiểm tra điểm
    if user.get("point", 0) < voucher["point"]:
        return jsonify({"error": "Không đủ điểm để đổi"}), 400
    
    # Kiểm tra đã đổi voucher này chưa
    exchanged_count = user_vouchers.count_documents({
        "username": username,
        "voucher_id": voucher_id
    })
    if exchanged_count >= voucher["maxPerUser"]:
        return jsonify({"error": "Đã đạt giới hạn đổi voucher này"}), 400
    
    # Trừ điểm
    new_point = user.get("point", 0) - voucher["point"]
    users.update_one(
        {"username": username},
        {"$set": {"point": new_point}}
    )
    
    # Tạo user_voucher
    user_voucher = {
        "username": username,
        "voucher_id": voucher_id,
        "partner": voucher["partner"],
        "point": voucher["point"],
        "status": "usable",
        "exchanged_at": datetime.now(),
        "used_at": None
    }
    user_vouchers.insert_one(user_voucher)
    
    return jsonify({
        "message": "Đổi voucher thành công",
        "new_point": new_point
    }), 200

@vouchers_bp.route("/users/<username>/vouchers", methods=["GET"])
def get_user_vouchers(username):
    # Kiểm tra database
    if not check_database():
        return jsonify({"vouchers": []}), 200
    
    try:
        user_vouchers_list = user_vouchers.find({"username": username})
        
        result = []
        for uv in user_vouchers_list:
            result.append({
                "_id": str(uv["_id"]),
                "voucher_id": uv["voucher_id"],
                "partner": uv["partner"],
                "point": uv["point"],
                "status": uv["status"],
                "exchanged_at": uv.get("exchanged_at", datetime.now()).isoformat(),
                "used_at": uv.get("used_at").isoformat() if uv.get("used_at") else None
            })
        
        return jsonify({"vouchers": result}), 200
    except Exception as e:
        return jsonify({"error": f"Lỗi database: {str(e)}"}), 500

@vouchers_bp.route("/vouchers/<voucher_id>/use", methods=["PUT"])
def mark_voucher_used(voucher_id):
    # Kiểm tra database
    if not check_database():
        return jsonify({"error": "Database không khả dụng"}), 503
    
    try:
        result = user_vouchers.update_one(
            {"_id": ObjectId(voucher_id)},
            {"$set": {"status": "used", "used_at": datetime.now()}}
        )
        
        if result.modified_count == 1:
            return jsonify({"message": "Đánh dấu voucher đã sử dụng thành công"}), 200
        else:
            return jsonify({"error": "Voucher không tồn tại"}), 404
    except Exception as e:
        return jsonify({"error": f"Lỗi: {str(e)}"}), 500

@vouchers_bp.route("/admin/vouchers", methods=["GET"])
def get_all_vouchers():
    # Kiểm tra database
    if not check_database():
        return jsonify([]), 200
    
    try:
        vouchers_list = vouchers.find().sort("created_at", -1)
        
        result = []
        for voucher in vouchers_list:
            result.append({
                "_id": str(voucher["_id"]),
                "partner": voucher["partner"],
                "point": voucher["point"],
                "maxPerUser": voucher["maxPerUser"],
                "expired": voucher["expired"],
                "status": voucher["status"],
                "created_at": voucher.get("created_at", datetime.now()).isoformat()
            })
        
        return jsonify(result), 200
    except Exception as e:
        return jsonify({"error": f"Lỗi database: {str(e)}"}), 500

@vouchers_bp.route("/voucher/<voucher_id>", methods=["GET"])
def get_voucher_detail(voucher_id):
    # Kiểm tra database
    if not check_database():
        return jsonify({"error": "Database không khả dụng"}), 503
    
    try:
        voucher = vouchers.find_one({"_id": ObjectId(voucher_id)})
        if not voucher:
            return jsonify({"error": "Voucher không tồn tại"}), 404
        
        return jsonify({
            "_id": str(voucher["_id"]),
            "partner": voucher["partner"],
            "point": voucher["point"],
            "maxPerUser": voucher["maxPerUser"],
            "expired": voucher["expired"],
            "status": voucher["status"]
        }), 200
    except Exception as e:
        return jsonify({"error": f"Lỗi: {str(e)}"}), 500

@vouchers_bp.route("/admin/vouchers/stats", methods=["GET"])
def get_voucher_stats():
    # Kiểm tra database
    if not check_database():
        return jsonify({
            "total": 0,
            "available": 0,
            "exchanged": 0,
            "used": 0
        }), 200
    
    try:
        total = vouchers.count_documents({})
        available = vouchers.count_documents({"status": "available"})
        exchanged = user_vouchers.count_documents({})
        used = user_vouchers.count_documents({"status": "used"})
        
        return jsonify({
            "total": total,
            "available": available,
            "exchanged": exchanged,
            "used": used
        }), 200
    except Exception as e:
        return jsonify({"error": f"Lỗi database: {str(e)}"}), 500