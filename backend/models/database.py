from pymongo import MongoClient
import gridfs
import os

MONGO_URI = "mongodb+srv://locnguyen2512cn_db_user:GreenRewards123@greenrewards.lqkojxf.mongodb.net/green_rewards?retryWrites=true&w=majority"

print("Đang kết nối MongoDB...")

try:
    client = MongoClient(MONGO_URI, serverSelectionTimeoutMS=10000)
    # Kiểm tra kết nối
    client.admin.command('ping')
    print("✓ Kết nối MongoDB thành công!")
    
    db = client["green_rewards"]
    
except Exception as e:
    print(f"✗ Lỗi kết nối MongoDB: {e}")
    print("⚠ Chế độ development: không kết nối database")
    # Tạo client và db giả để ứng dụng có thể chạy
    client = None
    db = None

# Collections - chỉ tạo nếu kết nối thành công
if db is not None:  # ĐÃ SỬA: thay if db: thành if db is not None:
    users = db["users"]
    vouchers = db["vouchers"]
    user_vouchers = db["user_vouchers"]
    partners = db["partners"]
    
    fs = gridfs.GridFS(db, collection="images")
    
    # Tạo index để tối ưu truy vấn
    try:
        # Index cho users
        users.create_index([("username", 1)], unique=True)
        users.create_index([("email", 1)], unique=True)
        users.create_index([("phone", 1)], unique=True)
        users.create_index([("role", 1)])
        users.create_index([("isAdmin", 1)])
        users.create_index([("isManager", 1)])
        
        # Index cho partners
        partners.create_index([("name", 1)], unique=True)
        partners.create_index([("status", 1)])
        
        # Index cho vouchers
        vouchers.create_index([("expired", 1)])
        vouchers.create_index([("status", 1)])
        vouchers.create_index([("partner", 1)])
        
        # Index cho user_vouchers
        user_vouchers.create_index([("username", 1)])
        user_vouchers.create_index([("voucher_id", 1)])
        user_vouchers.create_index([("status", 1)])
        
        print("✓ Đã tạo index")
        
        # Cập nhật tất cả user hiện có để thêm trường isManager nếu chưa có
        print("Đang cập nhật trường isManager cho users hiện có...")
        users_without_manager = users.find({"isManager": {"$exists": False}})
        count = 0
        for user in users_without_manager:
            role = user.get("role", "user")
            isManager = role in ["admin", "manager"]
            users.update_one(
                {"_id": user["_id"]},
                {"$set": {"isManager": isManager}}
            )
            count += 1
        if count > 0:
            print(f"✓ Đã cập nhật {count} users với trường isManager")
            
    except Exception as e:
        print(f"⚠ Lỗi tạo index hoặc cập nhật users: {e}")
else:
    # Tạo các biến None để tránh lỗi import
    users = vouchers = user_vouchers = partners = fs = None
    print("⚠ Chạy ở chế độ không có database")

def check_database():
    """Kiểm tra xem database có kết nối không"""
    return users is not None