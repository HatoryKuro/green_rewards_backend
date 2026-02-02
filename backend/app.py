from flask import Flask, request, jsonify
from flask_cors import CORS
from database import users
import hashlib
import os

app = Flask(__name__)
CORS(app)

# ---------- HASH ----------
def hash_password(pw):
    return hashlib.sha256(pw.encode()).hexdigest()

# ---------- ENSURE ADMIN (GIỮ NGUYÊN FLOW) ----------
users.update_one(
    {"username": "admin"},
    {"$set": {
        "username": "admin",
        "email": "admin@system.com",
        "phone": "0000000000",
        "password": hash_password("admin1"),
        "role": "admin",
        "isAdmin": True
    }},
    upsert=True
)
print("✅ Admin ensured")

# ---------- HOME ----------
@app.route("/")
def home():
    return "Green Rewards Backend OK"

# ---------- LOGIN (KHÔNG ĐỤNG) ----------
@app.route("/login", methods=["POST"])
def login():
    data = request.json

    user = users.find_one({"username": data.get("username")})
    if not user:
        return jsonify({"error": "User not found"}), 401

    if user["password"] != hash_password(data.get("password")):
        return jsonify({"error": "Wrong password"}), 401

    return jsonify({
        "username": user["username"],
        "role": user.get("role", "user")
    }), 200

# ---------- REGISTER (CHỈ THÊM EMAIL) ----------
@app.route("/register", methods=["POST"])
def register():
    data = request.json

    username = data.get("username")
    email = data.get("email")
    phone = data.get("phone")
    password = data.get("password")

    if not username or not email or not phone or not password:
        return jsonify({"error": "Thiếu dữ liệu"}), 400

    if users.find_one({"email": email}):
        return jsonify({"error": "Email đã tồn tại"}), 400

    if users.find_one({"phone": phone}):
        return jsonify({"error": "SĐT đã tồn tại"}), 400

    users.insert_one({
        "username": username,
        "email": email,
        "phone": phone,
        "password": hash_password(password),
        "role": "user",
        "isAdmin": False
    })

    return jsonify({"message": "Tạo tài khoản thành công"}), 200

# ---------- GET USERS (GIỮ NGUYÊN) ----------
@app.route("/users", methods=["GET"])
def get_users():
    return jsonify([
        {
            "id": str(u["_id"]),
            "username": u.get("username"),
            "email": u.get("email"),
            "phone": u.get("phone"),
            "role": u.get("role", "user"),
            "isAdmin": u.get("isAdmin", False)
        } for u in users.find()
    ])

# ---------- RUN ----------
if __name__ == "__main__":
    port = int(os.getenv("PORT", 10000))
    app.run(host="0.0.0.0", port=port)
