from pymongo import MongoClient
import os

MONGO_URI = "mongodb+srv://locnguyen2512cn_db_user:GreenRewards123@greenrewards.lqkojxf.mongodb.net/green_rewards?retryWrites=true&w=majority"

client = MongoClient(MONGO_URI)

db = client["green_rewards"]
users = db["users"]