from flask import Flask, request, jsonify
from flask_cors import CORS
from database import users
from bson.objectid import ObjectId
import hashlib
import os

app = Flask(__name__)
CORS(app)

def hash_password(pw):
    return hashlib.sha256(pw.encode()).hexdigest()

# 👉 TẠO ADMIN NẾU CHƯA CÓ
if users.find_one({"username": "admin"}) is None:
    users.insert_one({
        "username": "admin",
        "password": hash_password("123456"),
        "role": "admin"
    })
    print("✅ Admin created")

@app.route("/")
def home():
    return "Green Rewards Backend OK"

# ---------- LOGIN ----------
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
        "role": user["role"]
    })

# ---------- GET USERS (ADMIN) ----------
@app.route("/users", methods=["GET"])
def get_users():
    result = []
    for u in users.find():
        result.append({
            "id": str(u["_id"]),
            "username": u["username"],
            "role": u.get("role", "user")
        })
    return jsonify(result)

if __name__ == "__main__":
    port = int(os.getenv("PORT", 5001))
    app.run(host="0.0.0.0", port=port)
