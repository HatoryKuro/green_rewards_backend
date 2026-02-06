from database import users

def validate_user_exists(username=None, email=None, phone=None, user_id=None):
    """Kiểm tra user có tồn tại không"""
    query = {}
    if username:
        query["username"] = username
    if email:
        query["email"] = email
    if phone:
        query["phone"] = phone
    if user_id:
        query["_id"] = user_id
    
    return users.find_one(query) is not None

def check_duplicate_user(username, email, phone, exclude_id=None):
    """Kiểm tra trùng lặp user"""
    conditions = []
    
    if username:
        conditions.append({"username": username})
    if email:
        conditions.append({"email": email})
    if phone:
        conditions.append({"phone": phone})
    
    if not conditions:
        return False
    
    query = {"$or": conditions}
    if exclude_id:
        query["_id"] = {"$ne": exclude_id}
    
    return users.find_one(query) is not None