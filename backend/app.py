from flask import Flask, request, jsonify
from flask_cors import CORS
from database import users
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
        "history": []
    })

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

# =========================
# REGISTER
# =========================
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
        "point": 0,
        "usedBills": [],
        "history": []
    })

    return jsonify({"message": "OK"}), 200

# =========================
# GET USERS
# =========================
@app.route("/users", methods=["GET"])
def get_users():
    result = []

    for u in users.find():
        result.append({
            "id": str(u["_id"]),
            "username": u.get("username"),
            "email": u.get("email"),
            "phone": u.get("phone"),
            "role": u.get("role", "user"),
            "isAdmin": u.get("isAdmin", False),
            "point": safe_int(u.get("point", 0))
        })

    return jsonify(result), 200

# =========================
# ✅ GET USER BY USERNAME (FIX HISTORY FLUTTER)
# =========================
@app.route("/users/<username>", methods=["GET"])
def get_user_by_username(username):
    user = users.find_one({"username": username})
    if not user:
        return jsonify({"error": "User not found"}), 404

    return jsonify({
        "username": user.get("username"),
        "email": user.get("email"),
        "phone": user.get("phone"),
        "role": user.get("role", "user"),
        "isAdmin": user.get("isAdmin", False),
        "point": safe_int(user.get("point", 0)),
        "history": user.get("history", [])
    }), 200

# =========================
# DELETE USER
# =========================
@app.route("/users/<user_id>", methods=["DELETE"])
def delete_user(user_id):
    result = users.delete_one({"_id": ObjectId(user_id)})

    if result.deleted_count == 1:
        return jsonify({"message": "Deleted"}), 200

    return jsonify({"error": "Not found"}), 404

# =========================
# RESET POINT
# =========================
@app.route("/users/<user_id>/reset-point", methods=["PUT"])
def reset_point(user_id):
    result = users.update_one(
        {"_id": ObjectId(user_id)},
        {"$set": {"point": 0}}
    )

    if result.matched_count == 0:
        return jsonify({"error": "User not found"}), 404

    return jsonify({"message": "Point reset"}), 200

# =========================
# ADD POINT BY QR  ✅ FIX HISTORY
# =========================
@app.route("/scan/add-point", methods=["POST"])
def add_point_by_qr():
    data = request.json

    raw_username = data.get("username")
    partner = data.get("partner")
    bill_code = data.get("billCode")
    point = safe_int(data.get("point", 0))

    if not raw_username or not bill_code or point <= 0:
        return jsonify({"error": "Invalid data"}), 400

    # CẮT USERQR|
    if raw_username.startswith("USERQR|"):
        username = raw_username.split("|", 1)[1]
    else:
        username = raw_username

    user = users.find_one({"username": username})
    if not user:
        return jsonify({"error": "User not found"}), 404

    used_bills = user.get("usedBills", [])

    if bill_code in used_bills:
        return jsonify({"error": "Bill already used"}), 400

    users.update_one(
        {"_id": user["_id"]},
        {
            "$inc": {"point": point},
            "$push": {
                "usedBills": bill_code,
                "history": {
                    "type": "add",
                    "message": f"Cộng {point} điểm từ {partner}",
                    "partner": partner,
                    "bill": bill_code,
                    "point": point,
                    "time": datetime.now().strftime("%d/%m/%Y %H:%M")
                }
            }
        }
    )

    return jsonify({"message": "OK"}), 200

# =========================
# RUN
# =========================
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", 10000)))
