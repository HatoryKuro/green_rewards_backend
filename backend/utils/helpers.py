import hashlib
from flask import jsonify

def hash_password(pw):
    return hashlib.sha256(pw.encode()).hexdigest()

def safe_int(value):
    try:
        return int(value)
    except:
        return 0

def safe_str(value):
    if value is None:
        return ""
    return str(value)

def json_error(message, status_code=500):
    """Helper function to return JSON error"""
    return jsonify({"error": message}), status_code