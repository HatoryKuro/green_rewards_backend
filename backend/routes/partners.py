from flask import Blueprint, request, jsonify
from models.database import partners, check_database
from utils.helpers import json_error
from bson.objectid import ObjectId
from datetime import datetime

partners_bp = Blueprint('partners', __name__)

@partners_bp.route("/partners", methods=["GET"])
def get_partners():
    # Kiểm tra database
    if not check_database():
        return jsonify([]), 200
    
    try:
        partners_list = partners.find({"status": "active"}).sort("name", 1)
        
        result = []
        for p in partners_list:
            partner_data = {
                "id": str(p["_id"]),
                "name": p["name"],
                "type": p.get("type", ""),
                "description": p.get("description", ""),
                "image_id": p.get("image_id", ""),
                "status": p.get("status", "active"),
            }
            
            # Chỉ thêm các trường cũ nếu tồn tại
            if "price_range" in p:
                partner_data["price_range"] = p["price_range"]
            if "segment" in p:
                partner_data["segment"] = p["segment"]
            if "created_at" in p:
                partner_data["created_at"] = p["created_at"].isoformat()
                
            result.append(partner_data)
        
        return jsonify(result), 200
    except Exception as e:
        return json_error(f"Database error: {str(e)}", 500)

@partners_bp.route("/partners/<partner_id>", methods=["GET"])
def get_partner(partner_id):
    # Kiểm tra database
    if not check_database():
        return json_error("Database không khả dụng", 503)
    
    try:
        partner = partners.find_one({"_id": ObjectId(partner_id)})
        if not partner:
            return json_error("Partner not found", 404)
        
        return jsonify({
            "id": str(partner["_id"]),
            "name": partner["name"],
            "type": partner.get("type", ""),
            "description": partner.get("description", ""),
            "image_id": partner.get("image_id", ""),
            "status": partner.get("status", "active")
        }), 200
    except:
        return json_error("Invalid partner ID", 400)

@partners_bp.route("/admin/partners", methods=["POST"])
def create_partner():
    # Kiểm tra database
    if not check_database():
        return json_error("Database không khả dụng", 503)
    
    data = request.json
    
    if not data.get("name"):
        return json_error("Partner name is required", 400)
    
    existing = partners.find_one({"name": data["name"]})
    if existing:
        return json_error("Partner name already exists", 400)
    
    partner = {
        "name": data["name"],
        "type": data.get("type", ""),
        "description": data.get("description", ""),
        "image_id": data.get("image_id", None),
        "status": data.get("status", "active"),
        "created_at": datetime.now()
    }
    
    try:
        result = partners.insert_one(partner)
        return jsonify({
            "message": "Partner created successfully",
            "partner_id": str(result.inserted_id)
        }), 201
    except Exception as e:
        return json_error(f"Database error: {str(e)}", 500)

@partners_bp.route("/admin/partners/<partner_id>", methods=["PUT"])
def update_partner(partner_id):
    # Kiểm tra database
    if not check_database():
        return json_error("Database không khả dụng", 503)
    
    data = request.json
    
    try:
        partner = partners.find_one({"_id": ObjectId(partner_id)})
        if not partner:
            return json_error("Partner not found", 404)
        
        if "name" in data and data["name"] != partner["name"]:
            existing = partners.find_one({"name": data["name"], "_id": {"$ne": ObjectId(partner_id)}})
            if existing:
                return json_error("Partner name already exists", 400)
        
        update_data = {}
        fields = ["name", "type", "description", "image_id", "status"]
        for field in fields:
            if field in data:
                update_data[field] = data[field]
        
        result = partners.update_one(
            {"_id": ObjectId(partner_id)},
            {"$set": update_data}
        )
        
        if result.modified_count == 1:
            return jsonify({"message": "Partner updated successfully"}), 200
        else:
            return jsonify({"message": "No changes made"}), 200
            
    except:
        return json_error("Invalid partner ID", 400)

@partners_bp.route("/admin/partners/<partner_id>", methods=["DELETE"])
def delete_partner(partner_id):
    # Kiểm tra database
    if not check_database():
        return json_error("Database không khả dụng", 503)
    
    try:
        partner = partners.find_one({"_id": ObjectId(partner_id)})
        if not partner:
            return json_error("Partner not found", 404)
        
        if partner.get("image_id"):
            try:
                from models.database import fs
                fs.delete(ObjectId(partner["image_id"]))
            except:
                pass
        
        result = partners.update_one(
            {"_id": ObjectId(partner_id)},
            {"$set": {"status": "inactive"}}
        )
        
        if result.modified_count == 1:
            return jsonify({"message": "Partner deleted successfully"}), 200
        else:
            return json_error("Failed to delete partner", 500)
            
    except:
        return json_error("Invalid partner ID", 400)

@partners_bp.route("/partners/names", methods=["GET"])
def get_partner_names():
    # Kiểm tra database
    if not check_database():
        return jsonify([]), 200
    
    try:
        partners_list = partners.find({"status": "active"}).sort("name", 1)
        
        result = []
        for p in partners_list:
            result.append({
                "name": p["name"],
                "id": str(p["_id"])
            })
        
        return jsonify(result), 200
    except Exception as e:
        return json_error(f"Database error: {str(e)}", 500)