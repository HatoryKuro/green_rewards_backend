# backend/auth_routes.py
from flask import Blueprint, request, jsonify
from database import users
from utils import hash_password, check_database
from datetime import datetime

auth_bp = Blueprint('auth', __name__)

@auth_bp.route("/login", methods=["POST"])
def login():
    # Code đăng nhập từ file cũ
    pass

@auth_bp.route("/register", methods=["POST"])
def register():
    # Code đăng ký từ file cũ
    pass