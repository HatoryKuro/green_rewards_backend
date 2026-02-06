# backend/partner_routes.py
from flask import Blueprint, request, jsonify
from database import partners
from utils import check_database
from bson.objectid import ObjectId
from datetime import datetime

partner_bp = Blueprint('partner', __name__)

@partner_bp.route("/partners", methods=["GET"])
def get_partners():
    # Code lấy partners
    pass

@partner_bp.route("/admin/partners", methods=["POST"])
def create_partner():
    # Code tạo partner
    pass

# ... các hàm quản lý partner khác