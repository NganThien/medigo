from app import create_app
from app import db  # Thêm dòng này để gọi database ra

app = create_app()

if __name__ == '__main__':
    # --- THÊM ĐOẠN NÀY ĐỂ TẠO BẢNG MỚI ---
    with app.app_context():
        db.create_all()
        print("Đã kiểm tra và tạo các bảng (cart_items) còn thiếu thành công!")
    # -------------------------------------

    # Chạy server ở cổng 5000
    app.run(host='0.0.0.0', port=5000, debug=True)