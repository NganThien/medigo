# -*- coding: utf-8 -*-
"""
Custom Admin Panel for MediGo Pharmacy
Flask Blueprint with authentication, Bootstrap 5, Chart.js
"""
from flask import Blueprint, render_template, request, redirect, url_for, flash, session, jsonify
from functools import wraps
from . import db
from .models import User, Product, Category, Order, OrderDetail
from werkzeug.security import check_password_hash
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
