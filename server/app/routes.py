from flask import Blueprint, request, jsonify
from . import db
from .models import Product, User, Order, OrderDetail, Category, CartItem
from werkzeug.security import generate_password_hash, check_password_hash
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity

# --- KHỞI TẠO BLUEPRINT ---
main = Blueprint('main', __name__)

# --- 1. API ĐĂNG KÝ (Không cần khóa) ---
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

# --- 2. API ĐĂNG NHẬP (Đã cấp Token) ---
@main.route('/api/login', methods=['POST'])
def login():
    data = request.get_json()
    if not data or not data.get('phone') or not data.get('password'):
        return jsonify({'message': 'Nhập thiếu sđt hoặc mật khẩu!'}), 400
        
    user = User.query.filter_by(phone=data['phone']).first()
    
    if not user:
        return jsonify({'message': 'Sai tài khoản hoặc mật khẩu!'}), 401
    
    # Logic kiểm tra mật khẩu
    is_valid_password = False
    if user.password == data['password']:
        is_valid_password = True
    elif user.password.startswith('pbkdf2:') and check_password_hash(user.password, data['password']):
        is_valid_password = True
        
    if not is_valid_password:
        return jsonify({'message': 'Sai tài khoản hoặc mật khẩu!'}), 401
        
    # 🟢 TẠO TOKEN: Mã hóa ID người dùng thành 1 chìa khóa bí mật
    access_token = create_access_token(identity=str(user.id))
        
    return jsonify({
        'message': 'Đăng nhập thành công',
        'access_token': access_token, # 🟢 Trả chìa khóa về cho Flutter
        'user': {
            'id': user.id,
            'full_name': user.full_name,
            'phone': user.phone,
            'role': user.role,
            'is_admin': (user.role == 'admin'),
            'address': user.address
        }
    }), 200

# --- 3. API LẤY DANH SÁCH THUỐC (Không cần khóa) ---
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

# --- 3b. API LẤY DANH SÁCH DANH MỤC (Không cần khóa) ---
@main.route('/api/categories', methods=['GET'])
def get_categories():
    categories = Category.query.order_by(Category.name).all()
    return jsonify({'categories': [c.to_dict() for c in categories]})

# --- 4. API CHI TIẾT THUỐC (Không cần khóa) ---
@main.route('/api/products/<int:id>', methods=['GET'])
def get_product_detail(id):
    product = Product.query.get_or_404(id)
    return jsonify(product.to_dict())

# --- 5. API TẠO ĐƠN HÀNG (Đã khóa) ---
@main.route('/api/orders', methods=['POST'])
@jwt_required()
def create_order():
    data = request.get_json()
    current_user_id = get_jwt_identity() # 🟢 Bóc ID từ Token, bỏ qua data['user_id']
    
    if not data or not data.get('items'):
        return jsonify({'message': 'Dữ liệu không hợp lệ!'}), 400

    try:
        new_order = Order(
            user_id=current_user_id, # Lưu bằng ID bảo mật
            total_amount=data['total_amount'],
            status='pending',
            shipping_address=data.get('address', '')
        )
        db.session.add(new_order)
        db.session.flush()

        for item in data['items']:
            detail = OrderDetail(
                order_id=new_order.id,
                product_id=item['product_id'],
                quantity=item['quantity'],
                price_at_purchase=item['price']
            )
            db.session.add(detail)

        db.session.commit()
        return jsonify({'message': 'Đặt hàng thành công!', 'order_id': new_order.id}), 201

    except Exception as e:
        db.session.rollback()
        return jsonify({'message': f'Lỗi server: {str(e)}'}), 500

# --- 6. API LỊCH SỬ ĐƠN HÀNG (Đã khóa) ---
@main.route('/api/orders/history', methods=['POST', 'GET'])
@jwt_required()
def get_order_history():
    try:
        current_user_id = get_jwt_identity() # 🟢 Chỉ lấy đơn hàng của người đang cầm điện thoại

        orders = (
            Order.query
            .filter_by(user_id=current_user_id)
            .order_by(Order.created_at.desc())
            .all()
        )

        history = []
        for order in orders:
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
                'items': items_data
            })

        return jsonify({'orders': history}), 200
    except Exception as e:
        return jsonify({'message': f'Lỗi server: {str(e)}'}), 500

# --- 7. API CHI TIẾT MỘT ĐƠN HÀNG (Đã khóa) ---
@main.route('/api/orders/<int:order_id>', methods=['GET'])
@jwt_required()
def get_order_detail(order_id):
    current_user_id = get_jwt_identity()
    order = Order.query.get_or_404(order_id)

    # Chống hack: Xem trộm đơn hàng của người khác
    if str(order.user_id) != str(current_user_id):
        return jsonify({'message': 'Truy cập bị từ chối!'}), 403

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

# --- 8. API HỦY ĐƠN HÀNG (Đã khóa) ---
@main.route('/api/orders/<int:order_id>/cancel', methods=['PUT'])
@jwt_required()
def cancel_order(order_id):
    current_user_id = get_jwt_identity()
    order = Order.query.get_or_404(order_id)

    if str(order.user_id) != str(current_user_id):
        return jsonify({'message': 'Truy cập bị từ chối!'}), 403

    if order.status != 'pending':
        return jsonify({'message': 'Chỉ được hủy đơn hàng đang ở trạng thái Chờ xử lý!'}), 400

    try:
        order.status = 'cancelled'
        db.session.commit()
        return jsonify({'message': 'Đã hủy đơn hàng thành công!'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'message': f'Lỗi server: {str(e)}'}), 500

# --- 9. API ĐỒNG BỘ GIỎ HÀNG (Đã khóa toàn bộ) ---
@main.route('/api/cart/<int:user_id>', methods=['GET'])
@jwt_required()
def get_cart(user_id):
    current_user_id = get_jwt_identity()
    cart_items = CartItem.query.filter_by(user_id=current_user_id).all()
    return jsonify({'cart': [item.to_dict() for item in cart_items]}), 200

@main.route('/api/cart/add', methods=['POST'])
@jwt_required()
def add_to_cart():
    current_user_id = get_jwt_identity()
    data = request.get_json()
    product_id = data.get('product_id')
    quantity = data.get('quantity', 1)

    if not product_id:
        return jsonify({'message': 'Thiếu thông tin!'}), 400

    existing_item = CartItem.query.filter_by(user_id=current_user_id, product_id=product_id).first()
    if existing_item:
        existing_item.quantity += quantity
    else:
        new_item = CartItem(user_id=current_user_id, product_id=product_id, quantity=quantity)
        db.session.add(new_item)
        
    db.session.commit()
    return jsonify({'message': 'Đã đồng bộ giỏ hàng!'}), 200

@main.route('/api/cart/remove/<int:product_id>', methods=['DELETE'])
@jwt_required()
def remove_from_cart(product_id):
    current_user_id = get_jwt_identity()
    item = CartItem.query.filter_by(user_id=current_user_id, product_id=product_id).first()
    if item:
        db.session.delete(item)
        db.session.commit()
    return jsonify({'message': 'Đã xóa khỏi DB!'}), 200

@main.route('/api/cart/clear/<int:user_id>', methods=['DELETE'])
@jwt_required()
def clear_cart(user_id):
    current_user_id = get_jwt_identity()
    CartItem.query.filter_by(user_id=current_user_id).delete()
    db.session.commit()
    return jsonify({'message': 'Đã làm sạch giỏ!'}), 200