from flask import Flask, request, jsonify
from flask_cors import CORS
from database import users
from bson.objectid import ObjectId   # ✅ BẮT BUỘC
import hashlib
import os

app = Flask(__name__)
CORS(app)

def hash_password(pw):
    return hashlib.sha256(pw.encode()).hexdigest()

# ---------- ENSURE ADMIN ----------
admin = users.find_one({"username": "admin"})
if not admin:
    users.insert_one({
        "username": "admin",
        "email": "admin@system.com",
        "phone": "0000000000",
        "password": hash_password("admin1"),
        "role": "admin",
        "isAdmin": True,
        "point": 0
    })
    print("✅ Admin created")
else:
    print("ℹ️ Admin already exists – not overwritten")

# ---------- LOGIN ----------
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
        "point": user.get("point", 0)
    }), 200

# ---------- REGISTER ----------
@app.route("/register", methods=["POST"])
def register():
    data = request.json

    if users.find_one({"username": data["username"]}):
        return jsonify({"error": "Username tồn tại"}), 400

    users.insert_one({
        "username": data["username"],
        "email": data["email"],
        "phone": data["phone"],
        "password": hash_password(data["password"]),
        "role": "user",
        "isAdmin": False,
        "point": 0
    })

    return jsonify({"message": "OK"}), 200

# ---------- GET USERS ----------
@app.route("/users", methods=["GET"])
def get_users():
    return jsonify([
        {
            "id": str(u["_id"]),   # ✅ DÙNG ID
            "username": u["username"],
            "email": u["email"],
            "phone": u["phone"],
            "role": u.get("role", "user"),
            "isAdmin": u.get("isAdmin", False),
            "point": u.get("point", 0)
        } for u in users.find()
    ])

# ---------- DELETE USER ----------
@app.route("/users/<user_id>", methods=["DELETE"])
def delete_user(user_id):
    result = users.delete_one({"_id": ObjectId(user_id)})

    if result.deleted_count == 1:
        return jsonify({"message": "Deleted"}), 200
    return jsonify({"error": "Not found"}), 404

# ---------- RUN ----------
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", 10000)))
