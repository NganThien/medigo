from flask import Blueprint, request, jsonify
from . import db
from .models import Product, User, Order, OrderDetail, Category, CartItem
from werkzeug.security import generate_password_hash, check_password_hash

# --- KHỞI TẠO BLUEPRINT ---
main = Blueprint('main', __name__)

# --- 1. API ĐĂNG KÝ ---
@main.route('/api/register', methods=['POST'])
def register():
    data = request.get_json()
    if not data or not data.get('phone') or not data.get('password'):
        return jsonify({'message': 'Thiếu thông tin!'}), 400
    
    existing_user = User.query.filter_by(phone=data['phone']).first()
    if existing_user:
        return jsonify({'message': 'Số điện thoại đã tồn tại!'}), 409
    
    hashed_password = generate_password_hash(data['password'], method='pbkdf2:sha256')
    new_user = User(
        phone=data['phone'],
        password=hashed_password,
        full_name=data.get('full_name', 'Khách mới'),
    )
    db.session.add(new_user)
    db.session.commit()
    return jsonify({'message': 'Đăng ký thành công!'}), 201

# --- 2. API ĐĂNG NHẬP (ĐÃ SỬA) ---
@main.route('/api/login', methods=['POST'])
def login():
    data = request.get_json()
    if not data or not data.get('phone') or not data.get('password'):
        return jsonify({'message': 'Nhập thiếu sđt hoặc mật khẩu!'}), 400
        
    user = User.query.filter_by(phone=data['phone']).first()
    
    if not user:
        return jsonify({'message': 'Sai tài khoản hoặc mật khẩu!'}), 401
    
    # --- LOGIC KIỂM TRA MẬT KHẨU MỚI ---
    is_valid_password = False
    
    # Trường hợp 1: Mật khẩu khớp y hệt (Dành cho user tạo bằng SQL - 123456)
    if user.password == data['password']:
        is_valid_password = True
    # Trường hợp 2: Mật khẩu khớp dạng mã hóa (Dành cho user đăng ký qua App)
    elif user.password.startswith('pbkdf2:') and check_password_hash(user.password, data['password']):
        is_valid_password = True
        
    if not is_valid_password:
        return jsonify({'message': 'Sai tài khoản hoặc mật khẩu!'}), 401
    # -----------------------------------
        
    return jsonify({
        'message': 'Đăng nhập thành công',
        'user': {
            'id': user.id,
            'full_name': user.full_name,
            'phone': user.phone,
            'role': user.role,
            'is_admin': (user.role == 'admin'),
            'address': user.address
        }
    }), 200

# --- 3. API LẤY DANH SÁCH THUỐC (tìm kiếm theo tên + lọc theo category_id) ---
@main.route('/api/products', methods=['GET'])
def get_products():
    q = request.args.get('q') or request.args.get('search', '').strip()
    category_id = request.args.get('category_id', type=int)
    query = Product.query
    if q:
        query = query.filter(Product.name.ilike(f'%{q}%'))
    if category_id is not None:
        query = query.filter(Product.category_id == category_id)
    products = query.limit(None).all()
    output = [p.to_dict() for p in products]
    return jsonify({'products': output})


# --- 3b. API LẤY DANH SÁCH DANH MỤC ---
@main.route('/api/categories', methods=['GET'])
def get_categories():
    categories = Category.query.order_by(Category.name).all()
    return jsonify({'categories': [c.to_dict() for c in categories]})

# --- 4. API CHI TIẾT THUỐC ---
@main.route('/api/products/<int:id>', methods=['GET'])
def get_product_detail(id):
    product = Product.query.get_or_404(id)
    return jsonify(product.to_dict())

# --- 5. API TẠO ĐƠN HÀNG (MỚI) ---
@main.route('/api/orders', methods=['POST'])
def create_order():
    data = request.get_json()
    
    # 1. Kiểm tra dữ liệu đầu vào
    if not data or not data.get('user_id') or not data.get('items'):
        return jsonify({'message': 'Dữ liệu không hợp lệ!'}), 400

    try:
        # 2. Tạo Đơn hàng tổng (Bảng orders)
        new_order = Order(
            user_id=data['user_id'],
            total_amount=data['total_amount'],
            status='pending', # Mặc định là "Chờ xử lý"
            shipping_address=data.get('address', '')
        )
        db.session.add(new_order)
        db.session.flush() # Đẩy tạm vào DB để lấy được cái ID của đơn hàng vừa tạo (new_order.id)

        # 3. Tạo Chi tiết đơn hàng (Bảng order_details)
        for item in data['items']:
            detail = OrderDetail(
                order_id=new_order.id, # Gắn vào đơn hàng vừa tạo
                product_id=item['product_id'],
                quantity=item['quantity'],
                price_at_purchase=item['price']
            )
            db.session.add(detail)

        # 4. Chốt đơn (Lưu thật sự vào DB)
        db.session.commit()
        
        return jsonify({'message': 'Đặt hàng thành công!', 'order_id': new_order.id}), 201

    except Exception as e:
        db.session.rollback() # Nếu có lỗi thì hủy hết, không lưu dở dang
        return jsonify({'message': f'Lỗi server: {str(e)}'}), 500


# --- 6. API LỊCH SỬ ĐƠN HÀNG (Đã nâng cấp chuẩn Shopee) ---
@main.route('/api/orders/history', methods=['POST'])
def get_order_history():
    data = request.get_json()

    if not data or not data.get('user_id'):
        return jsonify({'message': 'Thiếu user_id!'}), 400

    try:
        user_id = data['user_id']

        orders = (
            Order.query
            .filter_by(user_id=user_id)
            .order_by(Order.created_at.desc())
            .all()
        )

        history = []
        for order in orders:
            # Lôi danh sách thuốc trong từng đơn hàng ra
            items_data = []
            for detail in order.details:
                product = Product.query.get(detail.product_id)
                if product:
                    items_data.append({
                        'name': product.name,
                        'image_url': product.image_url,
                        'quantity': detail.quantity,
                        'price': float(detail.price_at_purchase) if detail.price_at_purchase is not None else 0
                    })

            history.append({
                'id': order.id,
                'total_amount': float(order.total_amount) if order.total_amount is not None else 0,
                'status': order.status,
                'created_at': order.created_at.isoformat() if getattr(order, 'created_at', None) else None,
                'items': items_data # Nhét danh sách thuốc vào đây để Flutter đọc
            })

        return jsonify({'orders': history}), 200

    except Exception as e:
        return jsonify({'message': f'Lỗi server: {str(e)}'}), 500


# --- 7. API CHI TIẾT MỘT ĐƠN HÀNG ---
@main.route('/api/orders/<int:order_id>', methods=['GET'])
def get_order_detail(order_id):
    order = Order.query.get_or_404(order_id)

    # Lấy danh sách sản phẩm trong đơn (OrderDetail + Product)
    items = []
    for detail in order.details:
        product = Product.query.get(detail.product_id)
        if product:
            items.append({
                'product_id': product.id,
                'name': product.name,
                'image_url': product.image_url,
                'price_at_purchase': float(detail.price_at_purchase) if detail.price_at_purchase is not None else 0,
                'quantity': detail.quantity,
            })

    return jsonify({
        'id': order.id,
        'created_at': order.created_at.isoformat() if getattr(order, 'created_at', None) else None,
        'status': order.status,
        'total_amount': float(order.total_amount) if order.total_amount is not None else 0,
        'shipping_address': order.shipping_address or '',
        'items': items,
    }), 200


# --- 8. API HỦY ĐƠN HÀNG ---
@main.route('/api/orders/<int:order_id>/cancel', methods=['PUT'])
def cancel_order(order_id):
    order = Order.query.get_or_404(order_id)

    if order.status != 'pending':
        return jsonify({'message': 'Chỉ được hủy đơn hàng đang ở trạng thái Chờ xử lý!'}), 400

    try:
        order.status = 'cancelled'
        db.session.commit()
        return jsonify({'message': 'Đã hủy đơn hàng thành công!'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'message': f'Lỗi server: {str(e)}'}), 500

# --- 9. API ĐỒNG BỘ GIỎ HÀNG ---
@main.route('/api/cart/<int:user_id>', methods=['GET'])
def get_cart(user_id):
    cart_items = CartItem.query.filter_by(user_id=user_id).all()
    # to_dict() của CartItem đã được bạn viết rất chuẩn, kéo luôn thông tin Product đi kèm
    return jsonify({'cart': [item.to_dict() for item in cart_items]}), 200

@main.route('/api/cart/add', methods=['POST'])
def add_to_cart():
    data = request.get_json()
    user_id = data.get('user_id')
    product_id = data.get('product_id')
    quantity = data.get('quantity', 1)

    if not user_id or not product_id:
        return jsonify({'message': 'Thiếu thông tin!'}), 400

    # Kiểm tra xem sản phẩm đã có trong giỏ chưa
    existing_item = CartItem.query.filter_by(user_id=user_id, product_id=product_id).first()
    
    if existing_item:
        existing_item.quantity += quantity
    else:
        new_item = CartItem(user_id=user_id, product_id=product_id, quantity=quantity)
        db.session.add(new_item)
        
    db.session.commit()
    return jsonify({'message': 'Đã đồng bộ giỏ hàng!'}), 200

@main.route('/api/cart/remove/<int:user_id>/<int:product_id>', methods=['DELETE'])
def remove_from_cart(user_id, product_id):
    item = CartItem.query.filter_by(user_id=user_id, product_id=product_id).first()
    if item:
        db.session.delete(item)
        db.session.commit()
    return jsonify({'message': 'Đã xóa khỏi DB!'}), 200

@main.route('/api/cart/clear/<int:user_id>', methods=['DELETE'])
def clear_cart(user_id):
    CartItem.query.filter_by(user_id=user_id).delete()
    db.session.commit()
    return jsonify({'message': 'Đã làm sạch giỏ!'}), 200