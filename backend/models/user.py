from datetime import datetime

class User:
    def __init__(self, username, email, phone, password, role="user"):
        self.username = username
        self.email = email
        self.phone = phone
        self.password = password
        self.role = role
        self.isAdmin = role == "admin"
        self.isManager = role in ["admin", "manager"]
        self.point = 0
        self.usedBills = []
        self.history = []
        self.created_at = datetime.now()
    
    def to_dict(self):
        return {
            "username": self.username,
            "email": self.email,
            "phone": self.phone,
            "password": self.password,
            "role": self.role,
            "isAdmin": self.isAdmin,
            "isManager": self.isManager,
            "point": self.point,
            "usedBills": self.usedBills,
            "history": self.history,
            "created_at": self.created_at
        }