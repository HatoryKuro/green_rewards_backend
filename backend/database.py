from pymongo import MongoClient
import os

MONGO_URI = "mongodb+srv://locnguyen2512cn_db_user:GreenRewards123@greenrewards.lqkojxf.mongodb.net/green_rewards?retryWrites=true&w=majority"

client = MongoClient(MONGO_URI)

db = client["green_rewards"]
users = db["users"]

# Collections
users = db['users']
vouchers = db['vouchers']
user_vouchers = db['user_vouchers']
partners = db['partners']  # Thêm mới

# Tạo index để tối ưu truy vấn
partners.create_index([("name", 1)], unique=True)
partners.create_index([("status", 1)])
vouchers.create_index([("expired", 1)])
vouchers.create_index([("status", 1)])
user_vouchers.create_index([("username", 1)])
user_vouchers.create_index([("voucher_id", 1)])