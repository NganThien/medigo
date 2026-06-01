# -*- coding: utf-8 -*-
"""
Flask-Admin: Cấu hình trang quản trị cho Nhà thuốc (Phiên bản Xịn xò)
"""
import os
from flask import current_app, url_for
from flask_admin import Admin
from flask_admin.contrib.sqla import ModelView
from flask_admin.form.upload import ImageUploadField
from markupsafe import Markup  # Thêm thư viện để render HTML đẹp
from . import db
from .models import User, Product, Order, OrderDetail, Category


# ==========================================
# CÁC HÀM CẤU HÌNH UPLOAD ẢNH
# ==========================================
def _upload_path():
    base = current_app.static_folder or 'static'
    path = os.path.join(base, 'uploads', 'products')
    os.makedirs(path, exist_ok=True)
    return path

def _image_url_relative():
    return 'uploads/products/'

def _upload_path_categories():
    base = current_app.static_folder or 'static'
    path = os.path.join(base, 'uploads', 'categories')
    os.makedirs(path, exist_ok=True)
    return path

def _image_url_relative_categories():
    return 'uploads/categories/'


# ==========================================
# CÁC HÀM "TRANG ĐIỂM" GIAO DIỆN (FORMATTERS)
# ==========================================
def format_currency(view, context, model, name):
    """Định dạng tiền tệ VNĐ (vd: 31000 -> 31.000 đ)"""
    val = getattr(model, name)
    if val:
        formatted = "{:,.0f}".format(val).replace(',', '.')
        return f"{formatted} đ"
    return "0 đ"

def format_datetime(view, context, model, name):
    """Định dạng ngày giờ hiển thị cho đẹp"""
    val = getattr(model, name)
    if val:
        return val.strftime('%H:%M | %d/%m/%Y')
    return ""

def format_image_thumbnail(view, context, model, name):
    """Biến đường dẫn ảnh thành hình ảnh thu nhỏ 50x50"""
    image_path = getattr(model, name)
    if image_path:
        url = url_for('static', filename=image_path)
        return Markup(f'<img src="{url}" style="width:50px; height:50px; object-fit:cover; border-radius:5px; border:1px solid #ddd;">')
    return Markup('<span style="color:#999; font-style:italic;">Không có ảnh</span>')

# ----------------- ĐẶC BIỆT CHO ĐƠN HÀNG -----------------
def format_order_user(view, context, model, name):
    """Lấy tên và sđt khách hàng thay vì hiện mã ID"""
    user = User.query.get(model.user_id)
    if user:
        return Markup(f"<b style='color:#009688;'>{user.full_name}</b><br><small>{user.phone}</small>")
    return Markup("<span style='color:red;'>Khách ẩn danh</span>")

def format_order_items(view, context, model, name):
    """Quét vào bảng OrderDetail để lôi danh sách thuốc khách mua ra hiển thị"""
    if not model.details:
        return Markup("<span style='color:grey;'>Đơn rỗng</span>")
    
    html = "<ul style='margin-bottom:0; padding-left:15px; font-size: 13px;'>"
    for detail in model.details:
        product = Product.query.get(detail.product_id)
        p_name = product.name if product else "Sản phẩm ẩn"
        html += f"<li>{p_name} - <b style='color:#d32f2f;'>x{detail.quantity}</b></li>"
    html += "</ul>"
    return Markup(html)


# ==========================================
# THIẾT KẾ CÁC TRANG QUẢN TRỊ
# ==========================================

# --- 1. Người dùng ---
class UserAdminView(ModelView):
    column_list = ['id', 'phone', 'full_name', 'role', 'created_at']
    column_searchable_list = ['phone', 'full_name']
    column_filters = ['role']
    column_editable_list = ['full_name', 'role']
    
    # Đã xóa 'address' khỏi form_columns
    form_columns = ['phone', 'password', 'full_name', 'role'] 
    form_excluded_columns = ['created_at']
    
# --- 2. Danh mục ---
class CategoryAdminView(ModelView):
    column_list = ['id', 'image_url', 'name']
    column_labels = {'id': 'Mã DM', 'image_url': 'Ảnh đại diện', 'name': 'Tên danh mục'}
    column_searchable_list = ['name']
    column_formatters = {'image_url': format_image_thumbnail}
    form_columns = ['name', 'image_url']
    form_overrides = {'image_url': ImageUploadField}
    form_args = {
        'image_url': {
            'label': 'Tải ảnh lên',
            'base_path': lambda: _upload_path_categories(),
            'relative_path': lambda: _image_url_relative_categories(),
        }
    }


# --- 3. Sản phẩm (Thuốc) ---
class ProductAdminView(ModelView):
    column_list = ['id', 'image_url', 'name', 'category', 'price', 'description']
    column_labels = {
        'id': 'Mã', 'image_url': 'Hình ảnh', 'name': 'Tên thuốc', 
        'category': 'Danh mục', 'price': 'Giá bán', 'description': 'Mô tả'
    }
    column_searchable_list = ['name']
    column_editable_list = ['price']
    column_formatters = {
        'price': format_currency,
        'image_url': format_image_thumbnail
    }
    form_columns = ['name', 'price', 'category', 'description', 'image_url']
    form_overrides = {'image_url': ImageUploadField}
    form_args = {
        'image_url': {
            'label': 'Tải ảnh lên',
            'base_path': lambda: _upload_path(),
            'relative_path': lambda: _image_url_relative(),
        }
    }


# --- 4. ĐƠN HÀNG (Trái tim của hệ thống) ---
class OrderAdminView(ModelView):
    # Thêm cột ảo 'Chi tiết mua' và thay 'user_id' thành 'Thông tin khách'
    column_list = ['id', 'user_id', 'items_bought', 'total_amount', 'status', 'shipping_address', 'created_at']
    
    column_labels = {
        'id': 'Mã Đơn', 
        'user_id': 'Khách hàng', 
        'items_bought': 'Chi tiết mua', # Tên cột ảo tự chế
        'total_amount': 'Tổng tiền', 
        'status': 'Trạng thái', 
        'shipping_address': 'Địa chỉ nhận hàng', 
        'created_at': 'Giờ đặt hàng'
    }
    
    # Ép Flask-Admin chạy các hàm trang điểm đã viết ở trên
    column_formatters = {
        'user_id': format_order_user,
        'items_bought': format_order_items,
        'total_amount': format_currency,
        'created_at': format_datetime
    }
    
    column_searchable_list = ['shipping_address']
    column_sortable_list = ['id', 'total_amount', 'status', 'created_at']
    
    # Cho phép sửa trạng thái đơn cực nhanh ngay tại bảng
    column_editable_list = ['status']
    column_choices = {
        'status': [
            ('pending', 'Chờ xử lý'),
            ('shipping', 'Đang giao'),
            ('completed', 'Hoàn thành'),
            ('cancelled', 'Đã hủy'),
        ]
    }
    
    # Khi bấm nút Edit (bút chì), cho phép xem/sửa chi tiết từng hộp thuốc bên trong
    form_columns = ['user_id', 'total_amount', 'status', 'shipping_address']
    inline_models = [OrderDetail]


# --- 5. Khởi tạo ---
def init_admin(app):
    # Đã xóa template_mode='bootstrap4' gây lỗi
    admin = Admin(app, name='Trạm Thuốc - Admin')

    admin.add_view(UserAdminView(User, db.session, name='Người dùng', category='Hệ thống'))
    admin.add_view(CategoryAdminView(Category, db.session, name='Danh mục', category='Kho Thuốc'))
    admin.add_view(ProductAdminView(Product, db.session, name='Sản phẩm', category='Kho Thuốc'))
    admin.add_view(OrderAdminView(Order, db.session, name='Quản lý Đơn hàng', category='Bán hàng'))
    
    return admin