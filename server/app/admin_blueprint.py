# -*- coding: utf-8 -*-
"""
Custom Admin Panel for MediGo Pharmacy
Flask Blueprint with authentication, Bootstrap 5, Chart.js
"""
from flask import Blueprint, render_template, request, redirect, url_for, flash, session, jsonify
from functools import wraps
from . import db
from .models import User, Product, Category, Order, OrderDetail
from werkzeug.security import check_password_hash, generate_password_hash
from sqlalchemy import func, desc
import os

admin_bp = Blueprint('admin', __name__)

# ==========================================
# AUTHENTICATION DECORATORS
# ==========================================
def admin_required(f):
    """Decorator to ensure only authenticated admin users can access routes"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'admin_id' not in session:
            flash('Vui lòng đăng nhập để truy cập trang quản trị.', 'warning')
            return redirect(url_for('admin.login'))
        return f(*args, **kwargs)
    return decorated_function

# ==========================================
# LOGIN / LOGOUT ROUTES
# ==========================================
@admin_bp.route('/login', methods=['GET', 'POST'])
def login():
    """Admin login page"""
    if request.method == 'POST':
        phone = request.form.get('phone')
        password = request.form.get('password')
        
        user = User.query.filter_by(phone=phone).first()
        
        if user and user.role == 'admin' and check_password_hash(user.password, password):
            session['admin_id'] = user.id
            session['admin_name'] = user.full_name
            flash(f'Chào mừng {user.full_name}!', 'success')
            return redirect(url_for('admin.dashboard'))
        else:
            flash('Số điện thoại hoặc mật khẩu không đúng, hoặc bạn không có quyền admin.', 'danger')
    
    return render_template('admin/login.html')

@admin_bp.route('/logout')
def logout():
    """Admin logout"""
    session.clear()
    flash('Đã đăng xuất thành công.', 'info')
    return redirect(url_for('admin.login'))

# ==========================================
# DASHBOARD ROUTE
# ==========================================
@admin_bp.route('/dashboard')
@admin_required
def dashboard():
    """Admin dashboard with statistics and charts"""
    # Get statistics
    total_orders = Order.query.count()
    total_revenue = db.session.query(func.sum(Order.total_amount)).scalar() or 0
    total_products = Product.query.count()
    total_categories = Category.query.count()
    
    # Get recent orders
    recent_orders = Order.query.order_by(Order.created_at.desc()).limit(10).all()
    
    # Get revenue by month for chart (dummy data for now)
    revenue_data = [
        {'month': 'T1', 'revenue': 15000000},
        {'month': 'T2', 'revenue': 22000000},
        {'month': 'T3', 'revenue': 18000000},
        {'month': 'T4', 'revenue': 25000000},
        {'month': 'T5', 'revenue': 30000000},
        {'month': 'T6', 'revenue': 35000000},
    ]
    
    return render_template('admin/dashboard.html',
                         total_orders=total_orders,
                         total_revenue=total_revenue,
                         total_products=total_products,
                         total_categories=total_categories,
                         recent_orders=recent_orders,
                         revenue_data=revenue_data)

# ==========================================
# ORDER MANAGEMENT ROUTES
# ==========================================
@admin_bp.route('/orders')
@admin_required
def orders():
    """List all orders"""
    page = request.args.get('page', 1, type=int)
    per_page = 20
    
    orders = Order.query.order_by(Order.created_at.desc()).paginate(
        page=page, per_page=per_page, error_out=False
    )
    
    return render_template('admin/orders.html', orders=orders)

@admin_bp.route('/orders/<int:order_id>')
@admin_required
def order_detail(order_id):
    """View order details"""
    order = Order.query.get_or_404(order_id)
    return render_template('admin/order_detail.html', order=order)

@admin_bp.route('/orders/<int:order_id>/status', methods=['POST'])
@admin_required
def update_order_status(order_id):
    """Update order status"""
    order = Order.query.get_or_404(order_id)
    new_status = request.form.get('status')
    
    if new_status in ['pending', 'shipping', 'completed', 'cancelled']:
        order.status = new_status
        db.session.commit()
        flash('Đã cập nhật trạng thái đơn hàng thành công!', 'success')
    else:
        flash('Trạng thái không hợp lệ.', 'danger')
    
    return redirect(url_for('admin.order_detail', order_id=order_id))

@admin_bp.route('/orders/<int:order_id>/edit', methods=['POST'])
@admin_required
def edit_order(order_id):
    """Edit order status and shipping address"""
    order = Order.query.get_or_404(order_id)
    
    new_status = request.form.get('status')
    shipping_address = request.form.get('shipping_address')
    
    if new_status in ['pending', 'shipping', 'completed', 'cancelled']:
        order.status = new_status
    
    if shipping_address:
        order.shipping_address = shipping_address
    
    db.session.commit()
    flash('Đã cập nhật đơn hàng thành công!', 'success')
    
    return redirect(url_for('admin.orders'))

@admin_bp.route('/orders/<int:order_id>/delete', methods=['POST'])
@admin_required
def delete_order(order_id):
    """Delete order"""
    order = Order.query.get_or_404(order_id)
    
    # Delete order details first
    for detail in order.details:
        db.session.delete(detail)
    
    # Delete order
    db.session.delete(order)
    db.session.commit()
    flash('Đã xóa đơn hàng thành công!', 'success')
    
    return redirect(url_for('admin.orders'))

# ==========================================
# PRODUCT MANAGEMENT ROUTES
# ==========================================
@admin_bp.route('/products')
@admin_required
def products():
    """List all products with search and pagination"""
    page = request.args.get('page', 1, type=int)
    per_page = 20
    search = request.args.get('search', '')
    
    query = Product.query
    if search:
        query = query.filter(Product.name.ilike(f'%{search}%'))
    
    products = query.order_by(Product.id.desc()).paginate(
        page=page, per_page=per_page, error_out=False
    )
    categories = Category.query.all()
    
    return render_template('admin/products.html', products=products, categories=categories, search=search)

@admin_bp.route('/products/add', methods=['POST'])
@admin_required
def add_product():
    """Add new product"""
    name = request.form.get('name')
    price = request.form.get('price')
    category_id = request.form.get('category_id')
    description = request.form.get('description')
    image_url = request.form.get('image_url')
    unit = request.form.get('unit', 'Hộp')
    
    if name and price:
        product = Product(
            name=name,
            price=float(price),
            category_id=int(category_id) if category_id else None,
            description=description,
            image_url=image_url,
            unit=unit
        )
        db.session.add(product)
        db.session.commit()
        flash('Đã thêm sản phẩm thành công!', 'success')
    else:
        flash('Vui lòng nhập tên và giá sản phẩm.', 'danger')
    
    return redirect(url_for('admin.products'))

@admin_bp.route('/products/<int:product_id>/edit', methods=['POST'])
@admin_required
def edit_product(product_id):
    """Edit product"""
    product = Product.query.get_or_404(product_id)
    
    product.name = request.form.get('name')
    product.price = float(request.form.get('price'))
    product.category_id = int(request.form.get('category_id')) if request.form.get('category_id') else None
    product.description = request.form.get('description')
    product.image_url = request.form.get('image_url')
    product.unit = request.form.get('unit', 'Hộp')
    
    db.session.commit()
    flash('Đã cập nhật sản phẩm thành công!', 'success')
    
    return redirect(url_for('admin.products'))

@admin_bp.route('/products/<int:product_id>/delete', methods=['POST'])
@admin_required
def delete_product(product_id):
    """Delete product"""
    product = Product.query.get_or_404(product_id)
    db.session.delete(product)
    db.session.commit()
    flash('Đã xóa sản phẩm thành công!', 'success')
    
    return redirect(url_for('admin.products'))

# ==========================================
# USER MANAGEMENT ROUTES
# ==========================================
@admin_bp.route('/users')
@admin_required
def users():
    """List all users with search and pagination"""
    page = request.args.get('page', 1, type=int)
    per_page = 20
    search = request.args.get('search', '')
    
    query = User.query
    if search:
        query = query.filter(
            (User.phone.ilike(f'%{search}%')) |
            (User.full_name.ilike(f'%{search}%'))
        )
    
    users = query.order_by(User.created_at.desc()).paginate(
        page=page, per_page=per_page, error_out=False
    )
    
    return render_template('admin/users.html', users=users, search=search)

@admin_bp.route('/users/add', methods=['POST'])
@admin_required
def add_user():
    """Add new user"""
    phone = request.form.get('phone')
    password = request.form.get('password')
    full_name = request.form.get('full_name')
    role = request.form.get('role', 'user')
    address = request.form.get('address')
    
    # Check if phone already exists
    existing_user = User.query.filter_by(phone=phone).first()
    if existing_user:
        flash('Số điện thoại đã tồn tại!', 'danger')
        return redirect(url_for('admin.users'))
    
    if phone and password and full_name:
        user = User(
            phone=phone,
            password=generate_password_hash(password),
            full_name=full_name,
            role=role,
            address=address
        )
        db.session.add(user)
        db.session.commit()
        flash('Đã thêm khách hàng thành công!', 'success')
    else:
        flash('Vui lòng nhập số điện thoại, mật khẩu và họ tên.', 'danger')
    
    return redirect(url_for('admin.users'))

@admin_bp.route('/users/<int:user_id>/edit', methods=['POST'])
@admin_required
def edit_user(user_id):
    """Edit user"""
    user = User.query.get_or_404(user_id)
    
    # Prevent editing own role if current admin
    if user.id == session.get('admin_id'):
        flash('Bạn không thể chỉnh sửa thông tin của chính mình.', 'warning')
        return redirect(url_for('admin.users'))
    
    user.phone = request.form.get('phone')
    user.full_name = request.form.get('full_name')
    user.role = request.form.get('role')
    user.address = request.form.get('address')
    
    # Update password only if provided
    password = request.form.get('password')
    if password:
        user.password = generate_password_hash(password)
    
    db.session.commit()
    flash('Đã cập nhật khách hàng thành công!', 'success')
    
    return redirect(url_for('admin.users'))

@admin_bp.route('/users/<int:user_id>/delete', methods=['POST'])
@admin_required
def delete_user(user_id):
    """Delete user"""
    user = User.query.get_or_404(user_id)
    
    # Prevent deleting own account
    if user.id == session.get('admin_id'):
        flash('Bạn không thể xóa tài khoản của chính mình.', 'danger')
        return redirect(url_for('admin.users'))
    
    # Prevent deleting admin users
    if user.role == 'admin':
        flash('Không thể xóa tài khoản admin.', 'danger')
        return redirect(url_for('admin.users'))
    
    db.session.delete(user)
    db.session.commit()
    flash('Đã xóa khách hàng thành công!', 'success')
    
    return redirect(url_for('admin.users'))

# ==========================================
# CATEGORY MANAGEMENT ROUTES
# ==========================================
@admin_bp.route('/categories')
@admin_required
def categories():
    """List all categories"""
    categories = Category.query.order_by(Category.id.desc()).all()
    return render_template('admin/categories.html', categories=categories)

@admin_bp.route('/categories/add', methods=['POST'])
@admin_required
def add_category():
    """Add new category"""
    name = request.form.get('name')
    image_url = request.form.get('image_url')
    
    if name:
        category = Category(name=name, image_url=image_url)
        db.session.add(category)
        db.session.commit()
        flash('Đã thêm danh mục thành công!', 'success')
    else:
        flash('Vui lòng nhập tên danh mục.', 'danger')
    
    return redirect(url_for('admin.categories'))

@admin_bp.route('/categories/<int:category_id>/edit', methods=['POST'])
@admin_required
def edit_category(category_id):
    """Edit category"""
    category = Category.query.get_or_404(category_id)
    category.name = request.form.get('name')
    category.image_url = request.form.get('image_url')
    db.session.commit()
    flash('Đã cập nhật danh mục thành công!', 'success')
    
    return redirect(url_for('admin.categories'))

@admin_bp.route('/categories/<int:category_id>/delete', methods=['POST'])
@admin_required
def delete_category(category_id):
    """Delete category"""
    category = Category.query.get_or_404(category_id)
    db.session.delete(category)
    db.session.commit()
    flash('Đã xóa danh mục thành công!', 'success')
    
    return redirect(url_for('admin.categories'))

import os
from flask import send_from_directory, abort

@admin_bp.route('/serve_media/<path:filename>')
def serve_media(filename):
    # Cắt dấu gạch chéo ở đầu nếu có
    filename = filename.lstrip('/')
    
    # Định vị thư mục mobile
    current_dir = os.path.dirname(os.path.abspath(__file__))
    mobile_dir = os.path.abspath(os.path.join(current_dir, '../../mobile'))
    
    # Ghép thành đường dẫn hoàn chỉnh
    file_path = os.path.join(mobile_dir, filename)
    
    # === ĐOẠN NÀY LÀ MÁY NGHE LÉN SẼ IN RA TERMINAL ===
    print("\n" + "="*30)
    print(f"🔍 DEBUG ẢNH:")
    print(f"👉 Tên file DB gửi lên: {filename}")
    print(f"👉 Thư mục Mobile: {mobile_dir}")
    print(f"👉 Đường dẫn Flask đang tìm: {file_path}")
    print(f"👉 File CÓ TỒN TẠI KHÔNG?: {os.path.exists(file_path)}")
    print("="*30 + "\n")
    # ===================================================
    
    if not os.path.exists(file_path):
        abort(404) # Trả về lỗi 404 nếu không thấy file
        
    return send_from_directory(mobile_dir, filename)