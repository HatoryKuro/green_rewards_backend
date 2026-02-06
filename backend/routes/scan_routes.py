# backend/scan_routes.py
from flask import Blueprint, request, jsonify
from database import users
from utils import check_database
from datetime import datetime

scan_bp = Blueprint('scan', __name__)

@scan_bp.route("/scan/add-point", methods=["POST"])
def add_point_by_qr():
    # Code quét QR
    pass