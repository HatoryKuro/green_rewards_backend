# backend/image_routes.py
from flask import Blueprint, request, jsonify, send_file
from database import partners, fs
from utils import check_database
from bson.objectid import ObjectId
from werkzeug.utils import secure_filename
from io import BytesIO

image_bp = Blueprint('image', __name__)

@image_bp.route("/admin/upload-partner-image", methods=["POST"])
def upload_partner_image():
    # Code upload ảnh
    pass

@image_bp.route("/image/<image_id>", methods=["GET"])
def get_image(image_id):
    # Code lấy ảnh
    pass