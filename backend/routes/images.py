from flask import Blueprint, request, jsonify, send_file  # Đảm bảo có jsonify
from models.database import partners, fs, check_database
from utils.helpers import json_error
from bson.objectid import ObjectId
from werkzeug.utils import secure_filename
from io import BytesIO
import gridfs

images_bp = Blueprint('images', __name__)

@images_bp.route("/admin/upload-partner-image", methods=["POST"])
def upload_partner_image():
    # Kiểm tra database
    if not check_database():
        return json_error("Database không khả dụng", 503)
    
    try:
        partner_id = request.form.get("partner_id")
        if not partner_id:
            return json_error("Thiếu partner_id", 400)
        
        partner = partners.find_one({"_id": ObjectId(partner_id)})
        if not partner:
            return json_error("Partner không tồn tại", 404)
        
        if 'image' not in request.files:
            return json_error("Không có file ảnh", 400)
        
        file = request.files['image']
        if file.filename == '':
            return json_error("Không có file được chọn", 400)
        
        allowed_extensions = {'png', 'jpg', 'jpeg', 'gif', 'webp'}
        if not '.' in file.filename or file.filename.rsplit('.', 1)[1].lower() not in allowed_extensions:
            return json_error("Định dạng file không hỗ trợ", 400)
        
        filename = secure_filename(f"partner_{partner_id}_{file.filename}")
        image_id = fs.put(
            file.read(),
            filename=filename,
            content_type=file.content_type,
            partner_id=partner_id,
            partner_name=partner['name']
        )
        
        partners.update_one(
            {"_id": ObjectId(partner_id)},
            {"$set": {"image_id": str(image_id)}}
        )
        
        return jsonify({
            "message": "Upload ảnh thành công",
            "image_id": str(image_id),
            "partner_name": partner['name']
        }), 200
        
    except Exception as e:
        return json_error(f"Lỗi upload: {str(e)}", 500)

@images_bp.route("/image/<image_id>", methods=["GET"])
def get_image(image_id):
    # Kiểm tra database
    if not check_database():
        return json_error("Database không khả dụng", 503)
    
    try:
        grid_out = fs.get(ObjectId(image_id))
        
        response = send_file(
            BytesIO(grid_out.read()),
            mimetype=grid_out.content_type,
            as_attachment=False,
            download_name=grid_out.filename
        )
        response.headers['Content-Disposition'] = f'inline; filename="{grid_out.filename}"'
        return response
        
    except gridfs.errors.NoFile:
        return json_error("Không tìm thấy ảnh", 404)
    except Exception as e:
        return json_error(f"Lỗi: {str(e)}", 500)

@images_bp.route("/admin/image/<image_id>", methods=["DELETE"])
def delete_image(image_id):
    # Kiểm tra database
    if not check_database():
        return json_error("Database không khả dụng", 503)
    
    try:
        fs.delete(ObjectId(image_id))
        
        partners.update_one(
            {"image_id": image_id},
            {"$unset": {"image_id": ""}}
        )
        
        return jsonify({"message": "Xóa ảnh thành công"}), 200
    except Exception as e:
        return json_error(f"Lỗi: {str(e)}", 500)