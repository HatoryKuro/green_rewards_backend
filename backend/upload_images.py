import os
import gridfs
from pymongo import MongoClient
from datetime import datetime

# Kết nối MongoDB
MONGO_URI = "mongodb+srv://locnguyen2512cn_db_user:GreenRewards123@greenrewards.lqkojxf.mongodb.net/green_rewards?retryWrites=true&w=majority"
client = MongoClient(MONGO_URI)
db = client["green_rewards"]
fs = gridfs.GridFS(db, collection='images')
partners = db['partners']

# Map tên partner với tên file ảnh
partner_images = {
    "May Cha": "1.png",
    "TuTiMi": "2.png",
    "Sunday Basic": "3.png",
    "Sóng Sánh": "4.png",
    "Te Amo": "5.png",
    "Trà Sữa Boss": "6.png",
    "Hồng Trà Ngô Gia": "7.png",
    "Lục Trà Thăng Hoa": "8.png",
    "Viên Viên": "9.png",
    "TocoToco": "10.png"
}

def upload_images(image_folder="images"):
    for partner_name, image_file in partner_images.items():
        image_path = os.path.join(image_folder, image_file)
        
        if not os.path.exists(image_path):
            print(f"⚠️ Không tìm thấy ảnh: {image_path}")
            continue
        
        # Tìm partner trong database
        partner = partners.find_one({"name": partner_name})
        if not partner:
            print(f"⚠️ Không tìm thấy partner: {partner_name}")
            continue
        
        print(f"📤 Đang upload ảnh cho {partner_name}...")
        
        # Đọc và upload ảnh
        with open(image_path, 'rb') as f:
            image_data = f.read()
            image_id = fs.put(
                image_data,
                filename=image_file,
                content_type="image/png",
                partner_id=str(partner["_id"]),
                partner_name=partner_name,
                uploaded_at=datetime.now()
            )
        
        # Cập nhật partner
        partners.update_one(
            {"_id": partner["_id"]},
            {"$set": {"image_id": str(image_id)}}
        )
        
        print(f"✅ Đã upload ảnh cho {partner_name}: {image_file} (ID: {image_id})")

if __name__ == "__main__":
    print("🚀 Bắt đầu upload ảnh partners...")
    upload_images()
    print("🎉 Upload hoàn tất!")