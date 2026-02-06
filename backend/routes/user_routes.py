# backend/user_routes.py
from flask import Blueprint, request, jsonify
from database import users
from utils import safe_int, check_database
from bson.objectid import ObjectId
from datetime import datetime

user_bp = Blueprint('user', __name__)

@user_bp.route("/users", methods=["GET"])
def get_all_users():
    # Code lấy tất cả users
    pass

@user_bp.route("/users/<user_id>/role", methods=["PUT"])
def update_user_role(user_id):
    # Code cập nhật role
    pass

# ... các hàm quản lý user khác