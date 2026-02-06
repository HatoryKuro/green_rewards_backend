# backend/voucher_routes.py
from flask import Blueprint, request, jsonify
from database import vouchers, user_vouchers, users
from utils import check_database
from bson.objectid import ObjectId
from datetime import datetime

voucher_bp = Blueprint('voucher', __name__)

@voucher_bp.route("/admin/vouchers", methods=["POST"])
def create_voucher():
    # Code tạo voucher
    pass

@voucher_bp.route("/vouchers", methods=["GET"])
def get_available_vouchers():
    # Code lấy voucher
    pass

# ... các hàm quản lý voucher khác