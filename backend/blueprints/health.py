from flask import Blueprint, jsonify
from database import users

health_bp = Blueprint('health', __name__)

def check_database():
    """Kiểm tra xem database có kết nối không"""
    return users is not None

@health_bp.route("/health", methods=["GET"])
def health_check():
    return jsonify({
        "status": "ok" if check_database() else "error",
        "database": "connected" if check_database() else "disconnected",
        "message": "Service is running" if check_database() else "Database connection failed"
    }), 200 if check_database() else 503