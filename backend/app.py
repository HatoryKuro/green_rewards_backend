from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
from database import users, vouchers, user_vouchers, partners, fs
from bson.objectid import ObjectId
from datetime import datetime
import hashlib
import os
from werkzeug.utils import secure_filename
from io import BytesIO
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
            "image_id": None  # Thay image_url bằng image_id
        },
        {
            "name": "TuTiMi",
            "type": "Trà sữa",
            "price_range": "30.000đ – 50.000đ",
            "segment": "Học sinh – sinh viên",
            "description": "Vị ngọt vừa, menu dễ uống, giá mềm",
            "status": "active",
            "image_id": None
        },
        {
            "name": "Sunday Basic",
            "type": "Trà sữa / Đồ uống",
            "price_range": "35.000đ – 60.000đ",
            "segment": "Dân văn phòng",
            "description": "Thiết kế tối giản, đồ uống hiện đại",
            "status": "active",
            "image_id": None
        },
        {
            "name": "Sóng Sánh",
            "type": "Trà sữa",
            "price_range": "28.000đ – 48.000đ",
            "segment": "Giới trẻ",
            "description": "Trân châu ngon, vị béo rõ",
            "status": "active",
            "image_id": None
        },
        {
            "name": "Te Amo",
            "type": "Trà sữa",
            "price_range": "30.000đ – 55.000đ",
            "segment": "Cặp đôi – giới trẻ",
            "description": "Phong cách lãng mạn, menu sáng tạo",
            "status": "active",
            "image_id": None
        },
        {
            "name": "Trà Sữa Boss",
            "type": "Trà sữa",
            "price_range": "25.000đ – 45.000đ",
            "segment": "Sinh viên",
            "description": "Giá rẻ, topping nhiều",
            "status": "active",
            "image_id": None
        },
        {
            "name": "Hồng Trà Ngô Gia",
            "type": "Trà / Hồng trà",
            "price_range": "40.000đ – 70.000đ",
            "segment": "Khách thích trà nguyên vị",
            "description": "Trà đậm vị, ít ngọt, cao cấp",
            "status": "active",
            "image_id": None
        },
        {
            "name": "Lục Trà Thăng Hoa",
            "type": "Trà trái cây",
            "price_range": "35.000đ – 60.000đ",
            "segment": "Người thích healthy",
            "description": "Trà thanh, trái cây tươi",
            "status": "active",
            "image_id": None
        },
        {
            "name": "Viên Viên",
            "type": "Trà sữa",
            "price_range": "30.000đ – 50.000đ",
            "segment": "Giới trẻ",
            "description": "Vị béo, topping handmade",
            "status": "active",
            "image_id": None
        },
        {
            "name": "TocoToco",
            "type": "Trà sữa",
            "price_range": "30.000đ – 55.000đ",
            "segment": "Đại chúng",
            "description": "Chuỗi lớn, chất lượng ổn định",
            "status": "active",
            "image_id": None
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
# AUTH ROUTES
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
        return jsonify({"error": "Sai tài khoản hoặc mật khẩu"}), 401

    return jsonify({
        "_id": str(user["_id"]),
        "username": user["username"],
        "email": user["email"],
        "phone": user["phone"],
        "role": user.get("role", "user"),
        "isAdmin": user.get("isAdmin", False),
        "point": safe_int(user.get("point", 0))
    }), 200

@app.route("/register", methods=["POST"])
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
    
    # Tạo user mới
    new_user = {
        "username": data["username"],
        "email": data["email"],
        "phone": data["phone"],
        "password": hash_password(data["password"]),
        "role": "user",
        "isAdmin": False,
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

# =========================
# USER MANAGEMENT ROUTES
# =========================

@app.route("/users", methods=["GET"])
def get_all_users():
    try:
        users_list = users.find({"role": "user"}).sort("created_at", -1)
        
        result = []
        for user in users_list:
            result.append({
                "_id": str(user["_id"]),
                "id": str(user["_id"]),
                "username": user["username"],
                "email": user["email"],
                "phone": user["phone"],
                "role": user.get("role", "user"),
                "isAdmin": user.get("isAdmin", False),
                "point": safe_int(user.get("point", 0)),
                "created_at": user.get("created_at", datetime.now()).isoformat()
            })
        
        return jsonify(result), 200
    except Exception as e:
        return jsonify({"error": f"Lỗi database: {str(e)}"}), 500

@app.route("/users/<user_id>", methods=["DELETE"])
def delete_user(user_id):
    try:
        # Không cho xóa admin
        user = users.find_one({"_id": ObjectId(user_id)})
        if user and user.get("isAdmin"):
            return jsonify({"error": "Không thể xóa tài khoản admin"}), 400
        
        result = users.delete_one({"_id": ObjectId(user_id)})
        if result.deleted_count == 1:
            return jsonify({"message": "Xóa user thành công"}), 200
        else:
            return jsonify({"error": "User không tồn tại"}), 404
    except Exception as e:
        return jsonify({"error": f"Lỗi: {str(e)}"}), 500

@app.route("/users/<user_id>/reset-point", methods=["PUT"])
def reset_user_point(user_id):
    try:
        result = users.update_one(
            {"_id": ObjectId(user_id)},
            {"$set": {"point": 0}}
        )
        
        if result.modified_count == 1:
            return jsonify({"message": "Reset điểm thành công"}), 200
        else:
            return jsonify({"error": "User không tồn tại"}), 404
    except Exception as e:
        return jsonify({"error": f"Lỗi: {str(e)}"}), 500

@app.route("/users/<username>", methods=["GET"])
def get_user_by_username(username):
    try:
        user = users.find_one({"username": username})
        if not user:
            return jsonify({"error": "User không tồn tại"}), 404
        
        return jsonify({
            "_id": str(user["_id"]),
            "username": user["username"],
            "email": user["email"],
            "phone": user["phone"],
            "role": user.get("role", "user"),
            "isAdmin": user.get("isAdmin", False),
            "point": safe_int(user.get("point", 0)),
            "history": user.get("history", []),
            "usedBills": user.get("usedBills", [])
        }), 200
    except Exception as e:
        return jsonify({"error": f"Lỗi: {str(e)}"}), 500

# =========================
# SCAN QR & POINT ROUTES
# =========================

@app.route("/scan/add-point", methods=["POST"])
def add_point_by_qr():
    data = request.json
    
    required_fields = ["username", "partner", "billCode", "point"]
    for field in required_fields:
        if not data.get(field):
            return jsonify({"error": f"Thiếu trường {field}"}), 400
    
    username = data["username"]
    partner = data["partner"]
    bill_code = data["billCode"]
    point = int(data["point"])
    
    # Kiểm tra user
    user = users.find_one({"username": username})
    if not user:
        return jsonify({"error": "User không tồn tại"}), 404
    
    # Kiểm tra bill code đã dùng chưa
    if bill_code in user.get("usedBills", []):
        return jsonify({"error": "Hóa đơn đã được sử dụng"}), 400
    
    # Cập nhật điểm và lịch sử
    new_point = user.get("point", 0) + point
    history_entry = {
        "date": datetime.now().isoformat(),
        "partner": partner,
        "billCode": bill_code,
        "point": point,
        "type": "earn"
    }
    
    users.update_one(
        {"username": username},
        {
            "$set": {"point": new_point},
            "$push": {"history": history_entry},
            "$addToSet": {"usedBills": bill_code}
        }
    )
    
    return jsonify({
        "message": "Cộng điểm thành công",
        "new_point": new_point
    }), 200

# =========================
# VOUCHER ROUTES
# =========================

@app.route("/admin/vouchers", methods=["POST"])
def create_voucher():
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

@app.route("/vouchers", methods=["GET"])
def get_available_vouchers():
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

@app.route("/users/<username>/exchange-voucher", methods=["POST"])
def exchange_voucher(username):
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

@app.route("/users/<username>/vouchers", methods=["GET"])
def get_user_vouchers(username):
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

@app.route("/vouchers/<voucher_id>/use", methods=["PUT"])
def mark_voucher_used(voucher_id):
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

@app.route("/admin/vouchers", methods=["GET"])
def get_all_vouchers():
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

@app.route("/vouchers/<voucher_id>", methods=["GET"])
def get_voucher_detail(voucher_id):
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

@app.route("/admin/vouchers/stats", methods=["GET"])
def get_voucher_stats():
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

# =========================
# IMAGE UPLOAD & RETRIEVAL (GridFS)
# =========================

# 1. Upload ảnh cho partner
@app.route("/admin/upload-partner-image", methods=["POST"])
def upload_partner_image():
    try:
        partner_id = request.form.get("partner_id")
        if not partner_id:
            return jsonify({"error": "Thiếu partner_id"}), 400
        
        # Kiểm tra partner tồn tại
        partner = partners.find_one({"_id": ObjectId(partner_id)})
        if not partner:
            return jsonify({"error": "Partner không tồn tại"}), 404
        
        # Kiểm tra file ảnh
        if 'image' not in request.files:
            return jsonify({"error": "Không có file ảnh"}), 400
        
        file = request.files['image']
        if file.filename == '':
            return jsonify({"error": "Không có file được chọn"}), 400
        
        # Kiểm tra định dạng file
        allowed_extensions = {'png', 'jpg', 'jpeg', 'gif', 'webp'}
        if not '.' in file.filename or file.filename.rsplit('.', 1)[1].lower() not in allowed_extensions:
            return jsonify({"error": "Định dạng file không hỗ trợ"}), 400
        
        # Lưu ảnh vào GridFS
        filename = secure_filename(f"partner_{partner_id}_{file.filename}")
        image_id = fs.put(
            file.read(),
            filename=filename,
            content_type=file.content_type,
            partner_id=partner_id,
            partner_name=partner['name']
        )
        
        # Cập nhật partner với image_id
        partners.update_one(
            {"_id": ObjectId(partner_id)},
            {"$set": {"image_id": str(image_id)}}
        )
        
        return jsonify({
            "message": "Upload ảnh thành công",
            "image_id": str(image_id),
            "partner_name": partner['name']
        }), 200
        
    except Exception as e:
        return jsonify({"error": f"Lỗi upload: {str(e)}"}), 500

# 2. Lấy ảnh từ GridFS
@app.route("/image/<image_id>", methods=["GET"])
def get_image(image_id):
    try:
        # Tìm file trong GridFS
        grid_out = fs.get(ObjectId(image_id))
        
        # Trả về ảnh
        response = send_file(
            BytesIO(grid_out.read()),
            mimetype=grid_out.content_type,
            as_attachment=False,
            download_name=grid_out.filename
        )
        response.headers['Content-Disposition'] = f'inline; filename="{grid_out.filename}"'
        return response
        
    except gridfs.errors.NoFile:
        return jsonify({"error": "Không tìm thấy ảnh"}), 404
    except Exception as e:
        return jsonify({"error": f"Lỗi: {str(e)}"}), 500

# 3. Xóa ảnh
@app.route("/admin/image/<image_id>", methods=["DELETE"])
def delete_image(image_id):
    try:
        # Xóa từ GridFS
        fs.delete(ObjectId(image_id))
        
        # Cập nhật partner (xóa image_id)
        partners.update_one(
            {"image_id": image_id},
            {"$unset": {"image_id": ""}}
        )
        
        return jsonify({"message": "Xóa ảnh thành công"}), 200
    except Exception as e:
        return jsonify({"error": f"Lỗi: {str(e)}"}), 500

# =========================
# PARTNER ROUTES (cập nhật có image_id)
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
                "image_id": p.get("image_id", ""),  # Trả về image_id thay vì image_url
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
            "image_id": partner.get("image_id", ""),  # Trả về image_id
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
        "image_id": data.get("image_id", None),  # Thêm image_id
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
        fields = ["name", "type", "price_range", "segment", "description", "image_id", "status"]
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
        
        # Xóa ảnh nếu có
        if partner.get("image_id"):
            try:
                fs.delete(ObjectId(partner["image_id"]))
            except:
                pass
        
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

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", 10000)))