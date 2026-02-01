from flask import Flask, request, jsonify
from flask_cors import CORS
from database import users
import hashlib
import os

app = Flask(__name__)
CORS(app)

def hash_password(pw):
    return hashlib.sha256(pw.encode()).hexdigest()

# 🔥 ENSURE ADMIN
users.update_one(
    {"username": "admin"},
    {"$set": {
        "password": hash_password("admin1"),
        "role": "admin"
    }},
    upsert=True
)
print("✅ Admin ensured")

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
    }), 200

# ---------- GET USERS ----------
@app.route("/users", methods=["GET"])
def get_users():
    return jsonify([
        {
            "id": str(u["_id"]),
            "username": u["username"],
            "role": u.get("role", "user")
        } for u in users.find()
    ])

if __name__ == "__main__":
    port = int(os.getenv("PORT", 10000))
    app.run(host="0.0.0.0", port=port)
