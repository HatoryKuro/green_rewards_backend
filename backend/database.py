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
if db:
    users = db["users"]
    vouchers = db["vouchers"]
    user_vouchers = db["user_vouchers"]
    partners = db["partners"]
    
    fs = gridfs.GridFS(db, collection="images")
    
    # Tạo index để tối ưu truy vấn
    try:
        partners.create_index([("name", 1)], unique=True)
        partners.create_index([("status", 1)])
        vouchers.create_index([("expired", 1)])
        vouchers.create_index([("status", 1)])
        user_vouchers.create_index([("username", 1)])
        user_vouchers.create_index([("voucher_id", 1)])
        print("✓ Đã tạo index")
    except Exception as e:
        print(f"⚠ Lỗi tạo index: {e}")
else:
    # Tạo các biến None để tránh lỗi import
    users = vouchers = user_vouchers = partners = fs = None
    print("⚠ Chạy ở chế độ không có database")