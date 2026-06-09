from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS
from flask_migrate import Migrate
import os
from flask_jwt_extended import JWTManager

# Khởi tạo DB nhưng chưa kết nối
db = SQLAlchemy()
migrate = Migrate()

def create_app():
    app = Flask(__name__)
    
    # Cấu hình CORS (Cho phép Flutter gọi vào)
    CORS(app)

    # Cấu hình Database
    db_user = os.environ.get('MYSQL_USER', 'root')
    db_pass = os.environ.get('MYSQL_ROOT_PASSWORD', '123456')
    # Mặc định localhost để chạy seed/script trên máy; trong Docker set MYSQL_HOST=db
    db_host = os.environ.get('MYSQL_HOST', 'localhost')
    db_name = os.environ.get('MYSQL_DATABASE', 'pharmacy_db')
    
    app.config['SQLALCHEMY_DATABASE_URI'] = f'mysql+pymysql://{db_user}:{db_pass}@{db_host}/{db_name}'
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

    #BẬT TÍNH NĂNG BẢO MẬT
    app.config['JWT_SECRET_KEY'] = 'medigo_super_secret_key_bachkhoa_2026' # Chìa khóa bí mật để đóng mộc
    jwt = JWTManager(app)

    # Kết nối DB với App
    db.init_app(app)
    migrate.init_app(app, db)

    # Đăng ký các Route (API)
    from .routes import main
    app.register_blueprint(main)

    # Flask-Admin: Trang quản trị
    from .admin import init_admin
    init_admin(app)

    # Tự động tạo bảng nếu chưa có (Lệnh này chạy mỗi khi bật server)
    # with app.app_context():
    #    db.create_all()

    return app