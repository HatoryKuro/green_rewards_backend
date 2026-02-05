from flask import Flask, request, jsonify
from flask_cors import CORS
from database import users, vouchers, user_vouchers, partners
from bson.objectid import ObjectId
from datetime import datetime
import hashlib
import os

app = Flask(__name__)
CORS(app)

# =========================
# UTILS
# =========================
def hash_password(pw):
    return hashlib.sha256(pw.encode()).hexdigest()

def safe_int(value):
    try:
        return int(value)
    except:
        return 0

def safe_str(value):
    if value is None:
        return ""
    return str(value)

# =========================
# ENSURE DEFAULT PARTNERS
# =========================
def ensure_default_partners():
    default_partners = [
        {
            "name": "May Cha",
            "type": "Trà sữa",
            "price_range": "25.000đ – 45.000đ",
            "segment": "Sinh viên – giới trẻ",
            "description": "Phong cách trẻ trung, vị trà đậm, topping đa dạng",
            "status": "active",
            "image_url": ""
        },
        {
            "name": "TuTiMi",
            "type": "Trà sữa",
            "price_range": "30.000đ – 50.000đ",
            "segment": "Học sinh – sinh viên",
            "description": "Vị ngọt vừa, menu dễ uống, giá mềm",
            "status": "active",
            "image_url": ""
        },
        {
            "name": "Sunday Basic",
            "type": "Trà sữa / Đồ uống",
            "price_range": "35.000đ – 60.000đ",
            "segment": "Dân văn phòng",
            "description": "Thiết kế tối giản, đồ uống hiện đại",
            "status": "active",
            "image_url": ""
        },
        {
            "name": "Sóng Sánh",
            "type": "Trà sữa",
            "price_range": "28.000đ – 48.000đ",
            "segment": "Giới trẻ",
            "description": "Trân châu ngon, vị béo rõ",
            "status": "active",
            "image_url": ""
        },
        {
            "name": "Te Amo",
            "type": "Trà sữa",
            "price_range": "30.000đ – 55.000đ",
            "segment": "Cặp đôi – giới trẻ",
            "description": "Phong cách lãng mạn, menu sáng tạo",
            "status": "active",
            "image_url": ""
        },
        {
            "name": "Trà Sữa Boss",
            "type": "Trà sữa",
            "price_range": "25.000đ – 45.000đ",
            "segment": "Sinh viên",
            "description": "Giá rẻ, topping nhiều",
            "status": "active",
            "image_url": ""
        },
        {
            "name": "Hồng Trà Ngô Gia",
            "type": "Trà / Hồng trà",
            "price_range": "40.000đ – 70.000đ",
            "segment": "Khách thích trà nguyên vị",
            "description": "Trà đậm vị, ít ngọt, cao cấp",
            "status": "active",
            "image_url": ""
        },
        {
            "name": "Lục Trà Thăng Hoa",
            "type": "Trà trái cây",
            "price_range": "35.000đ – 60.000đ",
            "segment": "Người thích healthy",
            "description": "Trà thanh, trái cây tươi",
            "status": "active",
            "image_url": ""
        },
        {
            "name": "Viên Viên",
            "type": "Trà sữa",
            "price_range": "30.000đ – 50.000đ",
            "segment": "Giới trẻ",
            "description": "Vị béo, topping handmade",
            "status": "active",
            "image_url": ""
        },
        {
            "name": "TocoToco",
            "type": "Trà sữa",
            "price_range": "30.000đ – 55.000đ",
            "segment": "Đại chúng",
            "description": "Chuỗi lớn, chất lượng ổn định",
            "status": "active",
            "image_url": ""
        }
    ]
    
    for partner in default_partners:
        if not partners.find_one({"name": partner["name"]}):
            partner["created_at"] = datetime.now()
            partners.insert_one(partner)
            print(f"Created default partner: {partner['name']}")

# Gọi hàm khi khởi động
ensure_default_partners()

# =========================
# ENSURE ADMIN
# =========================
admin = users.find_one({"username": "admin"})
if not admin:
    users.insert_one({
        "username": "admin",
        "email": "admin@system.com",
        "phone": "0000000000",
        "password": hash_password("admin1"),
        "role": "admin",
        "isAdmin": True,
        "point": 0,
        "usedBills": [],
        "history": [],
        "created_at": datetime.now()
    })

# =========================
# PARTNER ROUTES
# =========================

# 1. Lấy danh sách tất cả partners
@app.route("/partners", methods=["GET"])
def get_partners():
    try:
        partners_list = partners.find({"status": "active"}).sort("name", 1)
        
        result = []
        for p in partners_list:
            result.append({
                "id": str(p["_id"]),
                "name": p["name"],
                "type": p.get("type", ""),
                "price_range": p.get("price_range", ""),
                "segment": p.get("segment", ""),
                "description": p.get("description", ""),
                "image_url": p.get("image_url", ""),
                "status": p.get("status", "active"),
                "created_at": p.get("created_at", "").isoformat() if "created_at" in p else ""
            })
        
        return jsonify(result), 200
    except Exception as e:
        return jsonify({"error": f"Database error: {str(e)}"}), 500

# 2. Lấy partner theo ID
@app.route("/partners/<partner_id>", methods=["GET"])
def get_partner(partner_id):
    try:
        partner = partners.find_one({"_id": ObjectId(partner_id)})
        if not partner:
            return jsonify({"error": "Partner not found"}), 404
        
        return jsonify({
            "id": str(partner["_id"]),
            "name": partner["name"],
            "type": partner.get("type", ""),
            "price_range": partner.get("price_range", ""),
            "segment": partner.get("segment", ""),
            "description": partner.get("description", ""),
            "image_url": partner.get("image_url", ""),
            "status": partner.get("status", "active")
        }), 200
    except:
        return jsonify({"error": "Invalid partner ID"}), 400

# 3. Tạo partner mới (Admin only)
@app.route("/admin/partners", methods=["POST"])
def create_partner():
    data = request.json
    
    # Kiểm tra required fields
    if not data.get("name"):
        return jsonify({"error": "Partner name is required"}), 400
    
    # Kiểm tra trùng tên
    existing = partners.find_one({"name": data["name"]})
    if existing:
        return jsonify({"error": "Partner name already exists"}), 400
    
    partner = {
        "name": data["name"],
        "type": data.get("type", ""),
        "price_range": data.get("price_range", ""),
        "segment": data.get("segment", ""),
        "description": data.get("description", ""),
        "image_url": data.get("image_url", ""),
        "status": data.get("status", "active"),
        "created_at": datetime.now()
    }
    
    try:
        result = partners.insert_one(partner)
        return jsonify({
            "message": "Partner created successfully",
            "partner_id": str(result.inserted_id)
        }), 201
    except Exception as e:
        return jsonify({"error": f"Database error: {str(e)}"}), 500

# 4. Cập nhật partner (Admin only)
@app.route("/admin/partners/<partner_id>", methods=["PUT"])
def update_partner(partner_id):
    data = request.json
    
    try:
        partner = partners.find_one({"_id": ObjectId(partner_id)})
        if not partner:
            return jsonify({"error": "Partner not found"}), 404
        
        # Kiểm tra nếu đổi tên thì không được trùng với partner khác
        if "name" in data and data["name"] != partner["name"]:
            existing = partners.find_one({"name": data["name"], "_id": {"$ne": ObjectId(partner_id)}})
            if existing:
                return jsonify({"error": "Partner name already exists"}), 400
        
        update_data = {}
        fields = ["name", "type", "price_range", "segment", "description", "image_url", "status"]
        for field in fields:
            if field in data:
                update_data[field] = data[field]
        
        result = partners.update_one(
            {"_id": ObjectId(partner_id)},
            {"$set": update_data}
        )
        
        if result.modified_count == 1:
            return jsonify({"message": "Partner updated successfully"}), 200
        else:
            return jsonify({"message": "No changes made"}), 200
            
    except:
        return jsonify({"error": "Invalid partner ID"}), 400

# 5. Xóa partner (Admin only - soft delete)
@app.route("/admin/partners/<partner_id>", methods=["DELETE"])
def delete_partner(partner_id):
    try:
        # Kiểm tra partner có tồn tại không
        partner = partners.find_one({"_id": ObjectId(partner_id)})
        if not partner:
            return jsonify({"error": "Partner not found"}), 404
        
        # Soft delete: đổi status thành inactive
        result = partners.update_one(
            {"_id": ObjectId(partner_id)},
            {"$set": {"status": "inactive"}}
        )
        
        if result.modified_count == 1:
            return jsonify({"message": "Partner deleted successfully"}), 200
        else:
            return jsonify({"error": "Failed to delete partner"}), 500
            
    except:
        return jsonify({"error": "Invalid partner ID"}), 400

# 6. Lấy danh sách partner names đơn giản (cho dropdown)
@app.route("/partners/names", methods=["GET"])
def get_partner_names():
    try:
        partners_list = partners.find({"status": "active"}).sort("name", 1)
        
        result = []
        for p in partners_list:
            result.append({
                "name": p["name"],
                "id": str(p["_id"])
            })
        
        return jsonify(result), 200
    except Exception as e:
        return jsonify({"error": f"Database error: {str(e)}"}), 500

# =========================
# LOGIN
# =========================
@app.route("/login", methods=["POST"])
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
        return jsonify({"error": "Login failed"}), 401

    return jsonify({
        "username": user["username"],
        "email": user["email"],
        "phone": user["phone"],
        "role": user.get("role", "user"),
        "isAdmin": user.get("isAdmin", False),
        "point": safe_int(user.get("point", 0))
    }), 200

# ... (giữ nguyên các phần khác của app.py: register, get_users, etc.)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", 10000)))