from pymongo import MongoClient
import os

MONGO_URI = "mongodb+srv://locnguyen2512cn_db_user:GreenRewards123@greenrewards.lqkojxf.mongodb.net/green_rewards?retryWrites=true&w=majority"

client = MongoClient(MONGO_URI)

db = client["green_rewards"]
users = db["users"]

# tạo sẵn admin nếu chưa có
if users.find_one({"username": "admin"}) is None:
    users.insert_one({
        "username": "admin",
        "password": "admin1",
        "email": "admin@greenrewards.com",
        "phone": "0000000000",
        "role": "admin"
    })
    print("✅ Admin account created")
