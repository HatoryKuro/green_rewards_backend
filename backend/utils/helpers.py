import hashlib
from bson.objectid import ObjectId

def hash_password(pw):
    """Hash mật khẩu"""
    return hashlib.sha256(pw.encode()).hexdigest()

def safe_int(value):
    """Chuyển đổi an toàn sang integer"""
    try:
        return int(value)
    except:
        return 0

def safe_str(value):
    """Chuyển đổi an toàn sang string"""
    if value is None:
        return ""
    return str(value)

def is_valid_objectid(id_str):
    """Kiểm tra ObjectId hợp lệ"""
    try:
        ObjectId(id_str)
        return True
    except:
        return False