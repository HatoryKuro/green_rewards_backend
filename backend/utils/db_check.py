from database import users

def check_database():
    """Kiểm tra xem database có kết nối không"""
    return users is not None