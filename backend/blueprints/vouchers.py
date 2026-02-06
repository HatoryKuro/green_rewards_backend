from flask import Blueprint, request, jsonify
from database import vouchers, user_vouchers, users
from bson.objectid import ObjectId
from datetime import datetime

vouchers_bp = Blueprint('vouchers', __name__)

@vouchers_bp.route("/admin/vouchers", methods=["POST"])
def create_voucher():
    # Copy code từ file gốc
    pass

@vouchers_bp.route("/vouchers", methods=["GET"])
def get_available_vouchers():
    # Copy code từ file gốc
    pass

# Thêm các route khác...