from flask import Blueprint, request, jsonify
from models.database import vouchers, user_vouchers, users, check_database
from utils.helpers import safe_int, json_error
from bson.objectid import ObjectId
from datetime import datetime

vouchers_bp = Blueprint('vouchers', __name__)

@vouchers_bp.route("/admin/vouchers", methods=["POST"])
def create_voucher():
    """Tạo voucher mới (Admin only) - ĐÃ SỬA LỖI KIỂM TRA maxPerUser"""
    # Kiểm tra database
    if not check_database():
        return json_error("Database không khả dụng", 503)
    
    data = request.json
    
    # SỬA: Kiểm tra trường có tồn tại trong data, không kiểm tra giá trị
    required_fields = ["partner", "point", "maxPerUser", "expired"]
    for field in required_fields:
        if field not in data:  # Sửa từ data.get(field) thành field not in data
            return json_error(f"Thiếu trường {field}", 400)
    
    # Kiểm tra kiểu dữ liệu
    try:
        point = int(data["point"])
        maxPerUser = int(data["maxPerUser"])
    except (ValueError, TypeError):
        return json_error("point và maxPerUser phải là số nguyên", 400)
    
    # Kiểm tra giá trị hợp lệ
    if point <= 0:
        return json_error("point phải lớn hơn 0", 400)
    
    if maxPerUser < 0:
        return json_error("maxPerUser phải lớn hơn hoặc bằng 0", 400)
    
    # Kiểm tra expired là string và định dạng hợp lệ
    expired = data["expired"]
    try:
        # Thử parse để kiểm tra định dạng ISO
        datetime.fromisoformat(expired.replace('Z', '+00:00'))
    except ValueError:
        return json_error("expired phải là chuỗi ISO 8601 hợp lệ", 400)
    
    # Kiểm tra expired không phải trong quá khứ
    expired_date = datetime.fromisoformat(expired.replace('Z', '+00:00'))
    if expired_date <= datetime.now():
        return json_error("expired phải ở tương lai", 400)
    
    new_voucher = {
        "partner": data["partner"],
        "point": point,
        "maxPerUser": maxPerUser,  # Có thể là 0 (không giới hạn)
        "expired": expired,
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
        return json_error(f"Lỗi database: {str(e)}", 500)

@vouchers_bp.route("/vouchers", methods=["GET"])
def get_available_vouchers():
    """Lấy danh sách voucher có sẵn để đổi"""
    # Kiểm tra database
    if not check_database():
        return jsonify([]), 200  # Trả về mảng rỗng
    
    try:
        # Chỉ lấy voucher còn hạn và available
        now = datetime.now()
        vouchers_list = vouchers.find({
            "status": "available",
            "expired": {"$gt": now.isoformat()}
        }).sort("point", 1)
        
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
        return json_error(f"Lỗi database: {str(e)}", 500)

@vouchers_bp.route("/users/<username>/exchange-voucher", methods=["POST"])
def exchange_voucher(username):
    """User đổi voucher bằng điểm"""
    # Kiểm tra database
    if not check_database():
        return json_error("Database không khả dụng", 503)
    
    data = request.json
    voucher_id = data.get("voucher_id")
    
    if not voucher_id:
        return json_error("Thiếu voucher_id", 400)
    
    # Kiểm tra user
    user = users.find_one({"username": username})
    if not user:
        return json_error("User không tồn tại", 404)
    
    # Kiểm tra voucher
    try:
        voucher = vouchers.find_one({"_id": ObjectId(voucher_id)})
    except Exception:
        return json_error("Voucher ID không hợp lệ", 400)
    
    if not voucher:
        return json_error("Voucher không tồn tại", 404)
    
    # Kiểm tra voucher còn available và chưa hết hạn
    if voucher.get("status") != "available":
        return json_error("Voucher không khả dụng", 400)
    
    try:
        expired_date = datetime.fromisoformat(voucher["expired"].replace('Z', '+00:00'))
        if expired_date <= datetime.now():
            return json_error("Voucher đã hết hạn", 400)
    except Exception:
        return json_error("Voucher có expired không hợp lệ", 400)
    
    # Kiểm tra điểm
    if user.get("point", 0) < voucher["point"]:
        return json_error("Không đủ điểm để đổi", 400)
    
    # Kiểm tra đã đổi voucher này chưa (chỉ kiểm tra nếu maxPerUser > 0)
    if voucher["maxPerUser"] > 0:
        exchanged_count = user_vouchers.count_documents({
            "username": username,
            "voucher_id": voucher_id
        })
        if exchanged_count >= voucher["maxPerUser"]:
            return json_error("Đã đạt giới hạn đổi voucher này", 400)
    
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
    """Lấy voucher của user"""
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
        return json_error(f"Lỗi database: {str(e)}", 500)

@vouchers_bp.route("/vouchers/<voucher_id>/use", methods=["PUT"])
def mark_voucher_used(voucher_id):
    """Đánh dấu voucher đã sử dụng"""
    # Kiểm tra database
    if not check_database():
        return json_error("Database không khả dụng", 503)
    
    try:
        result = user_vouchers.update_one(
            {"_id": ObjectId(voucher_id)},
            {"$set": {"status": "used", "used_at": datetime.now()}}
        )
        
        if result.modified_count == 1:
            return jsonify({"message": "Đánh dấu voucher đã sử dụng thành công"}), 200
        else:
            return json_error("Voucher không tồn tại", 404)
    except Exception as e:
        return json_error(f"Lỗi: {str(e)}", 500)

@vouchers_bp.route("/admin/vouchers", methods=["GET"])
def get_all_vouchers():
    """Lấy tất cả voucher (Admin)"""
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
        return json_error(f"Lỗi database: {str(e)}", 500)

@vouchers_bp.route("/voucher/<voucher_id>", methods=["GET"])
def get_voucher_detail(voucher_id):
    """Lấy chi tiết voucher"""
    # Kiểm tra database
    if not check_database():
        return json_error("Database không khả dụng", 503)
    
    try:
        voucher = vouchers.find_one({"_id": ObjectId(voucher_id)})
        if not voucher:
            return json_error("Voucher không tồn tại", 404)
        
        return jsonify({
            "_id": str(voucher["_id"]),
            "partner": voucher["partner"],
            "point": voucher["point"],
            "maxPerUser": voucher["maxPerUser"],
            "expired": voucher["expired"],
            "status": voucher["status"]
        }), 200
    except Exception as e:
        return json_error(f"Lỗi: {str(e)}", 500)

@vouchers_bp.route("/admin/vouchers/stats", methods=["GET"])
def get_voucher_stats():
    """Thống kê voucher (Admin)"""
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
        return json_error(f"Lỗi database: {str(e)}", 500)

@vouchers_bp.route("/admin/vouchers/<voucher_id>", methods=["DELETE"])
def delete_voucher(voucher_id):
    """Xóa voucher (Admin only)"""
    # Kiểm tra database
    if not check_database():
        return json_error("Database không khả dụng", 503)
    
    try:
        # Kiểm tra voucher có tồn tại không
        voucher = vouchers.find_one({"_id": ObjectId(voucher_id)})
        if not voucher:
            return json_error("Voucher không tồn tại", 404)
        
        # Xóa voucher
        result = vouchers.delete_one({"_id": ObjectId(voucher_id)})
        
        if result.deleted_count == 1:
            return jsonify({
                "message": "Xóa voucher thành công",
                "deleted_id": voucher_id
            }), 200
        else:
            return json_error("Không thể xóa voucher", 500)
    except Exception as e:
        return json_error(f"Lỗi khi xóa voucher: {str(e)}", 500)