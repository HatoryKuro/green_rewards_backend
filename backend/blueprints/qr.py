from flask import Blueprint, request, jsonify
from database import users
from datetime import datetime

qr_bp = Blueprint('qr', __name__)

@qr_bp.route("/scan/add-point", methods=["POST"])
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