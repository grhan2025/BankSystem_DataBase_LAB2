from django.shortcuts import render, redirect
from django.http import HttpResponse
from django.db import connection
from django.urls import reverse
from django.views.decorators.csrf import csrf_protect
from django.http import HttpResponseNotFound
from django.contrib import messages
from django.core.files.storage import default_storage
from django.core.files.base import ContentFile
from django.core.paginator import Paginator
import re
# Create your views here.

def client_management(request):
    with connection.cursor() as cursor:
        cursor.callproc('get_all_clients')
        results = cursor.fetchall()
    
    # 分页：每页显示10条
    paginator = Paginator(results, 10)
    page_number = request.GET.get('page', 1)  # 获取当前页码，默认为1
    page_obj = paginator.get_page(page_number)
    
    return render(request, "client/client_management.html", {
        "clients": page_obj,  # 分页后的数据
        "page_obj": page_obj  # 分页对象，用于显示页码
    })

def loan_management(request):
    with connection.cursor() as cursor:
        cursor.callproc('get_all_loans')
        results = cursor.fetchall()

    return render(request, "loan/loan_management.html", {"loans": results})

def account_management(request):
    with connection.cursor() as cursor:
        # 获取储蓄账户信息
        cursor.callproc('get_saving_account_by_all')
        saving_accounts = cursor.fetchall()
        
        # 获取信用账户信息
        cursor.callproc('get_credit_account_by_all')
        credit_accounts = cursor.fetchall()
    
    # 合并账户信息
    accounts = saving_accounts + credit_accounts
    
    return render(request, 'account/account_management.html', {'accounts': accounts})

def bankinfo_management(request):
    with connection.cursor() as cursor:
        cursor.callproc('GetAllBanks')
        banks = cursor.fetchall()
    
    # 计算合计
    total_asset = sum(bank[2] for bank in banks if bank[2])
    total_loans = sum(bank[4] for bank in banks if bank[4])
    total_accounts = sum(bank[5] for bank in banks if bank[5])
    total_clients = sum(bank[6] for bank in banks if bank[6])
    
    return render(request, "bankinfo/bankinfo_management.html", {
        "banks": banks,
        "total_asset": total_asset,
        "total_loans": total_loans,
        "total_accounts": total_accounts,
        "total_clients": total_clients
    })
# 客户管理

# 客户添加
def client_add(request):
    # 自动生成客户ID的函数
    def generate_client_id():
        with connection.cursor() as cursor:
            cursor.execute("SELECT client_id FROM client ORDER BY client_id DESC LIMIT 1")
            last_id = cursor.fetchone()
            if last_id and last_id[0]:
                # 提取数字部分，如 C001 -> 1
                last_num = int(last_id[0][1:])
                new_num = last_num + 1
                return f"C{new_num:03d}"  # C001, C002...
            else:
                return "C001"
    
    if request.method == 'POST':
        # 获取表单数据
        client_id = request.POST.get('client_id')
        id_number = request.POST.get('id')
        name = request.POST.get('name')
        sex = request.POST.get('sex')
        address = request.POST.get('address')
        phone = request.POST.get('phone')
        email = request.POST.get('email')
        contact_name = request.POST.get('contact_name')
        contact_phone = request.POST.get('contact_phone')
        contact_email = request.POST.get('contact_email')
        contact_relation = request.POST.get('contact_relation')
        
        # 如果客户ID为空，自动生成
        if not client_id:
            client_id = generate_client_id()
        
        has_error = False
        import re
        
        # 验证客户ID格式（如果是用户手动填写的）
        if request.POST.get('client_id'):  # 用户手动填写了
            if not re.match(r'^C\d{3}$', client_id):
                messages.error(request, '❌ 客户ID格式错误：应为 C + 3位数字，如：C001')
                has_error = True
            else:
                # 检查客户ID是否已存在
                with connection.cursor() as cursor:
                    cursor.execute("SELECT COUNT(*) FROM client WHERE client_id = %s", [client_id])
                    if cursor.fetchone()[0] > 0:
                        messages.error(request, f'❌ 客户ID "{client_id}" 已存在，请使用其他ID')
                        has_error = True
        
        # 验证身份证号（18位）
        if id_number:
            if len(id_number) != 18:
                messages.error(request, '❌ 身份证号格式错误：应为18位')
                has_error = True
            elif not id_number[:17].isdigit():
                messages.error(request, '❌ 身份证号格式错误：前17位必须为数字')
                has_error = True
            elif not (id_number[17].isdigit() or id_number[17].upper() == 'X'):
                messages.error(request, '❌ 身份证号格式错误：最后一位应为数字或X')
                has_error = True
        else:
            messages.error(request, '❌ 身份证号不能为空')
            has_error = True
        
        # 验证姓名
        if not name:
            messages.error(request, '❌ 姓名不能为空')
            has_error = True
        
        # 验证性别
        if sex not in ['男', '女']:
            messages.error(request, '❌ 请选择性别')
            has_error = True
        
        # 验证地址
        if not address:
            messages.error(request, '❌ 地址不能为空')
            has_error = True
        
        # 验证手机号（11位，以1开头）
        if phone:
            if len(phone) != 11:
                messages.error(request, '❌ 手机号格式错误：应为11位数字')
                has_error = True
            elif not phone.isdigit():
                messages.error(request, '❌ 手机号格式错误：只能包含数字')
                has_error = True
            elif phone[0] != '1':
                messages.error(request, '❌ 手机号格式错误：应以1开头')
                has_error = True
        else:
            messages.error(request, '❌ 手机号不能为空')
            has_error = True
        
        # 验证邮箱（可选，但如果填写则检查格式）
        if email:
            if '@' not in email or '.' not in email:
                messages.error(request, '❌ 邮箱格式错误')
                has_error = True
        
        # 验证联系人姓名
        if not contact_name:
            messages.error(request, '❌ 联系人姓名不能为空')
            has_error = True
        
        # 验证联系人电话
        if not contact_phone:
            messages.error(request, '❌ 联系人电话不能为空')
            has_error = True
        else:
            if len(contact_phone) < 8 or len(contact_phone) > 11:
                messages.error(request, '❌ 联系人电话格式错误：应为8-11位')
                has_error = True
            elif not contact_phone.isdigit():
                messages.error(request, '❌ 联系人电话格式错误：只能包含数字')
                has_error = True
        
        # 验证联系人关系
        if not contact_relation:
            messages.error(request, '❌ 联系人关系不能为空')
            has_error = True
        
        # 验证联系人邮箱（可选）
        if contact_email and ('@' not in contact_email or '.' not in contact_email):
            messages.error(request, '❌ 联系人邮箱格式错误')
            has_error = True
        
        if not has_error:
            try:
                with connection.cursor() as cursor:
                    err = ''
                    cursor.callproc('add_client', [client_id, id_number, name, sex, address, phone, email, 
                        contact_name, contact_phone, contact_email, contact_relation, err])
                    cursor.execute('SELECT @_add_client_11')
                    err = cursor.fetchone()[0]
                    if err:
                        messages.error(request, f'添加客户失败：{err}')
                    else:
                        messages.success(request, f'✅ 客户 "{name}" (ID: {client_id}) 添加成功！')
                        return redirect(reverse("banksystem:detail_client", kwargs={'client_id': client_id}))
            except Exception as e:
                messages.error(request, f'添加客户时出错：{str(e)}')
        
        # 有错误时返回表单，保留用户输入
        return render(request, "client/add_client.html", {
            'client_id': client_id,
            'id_number': id_number,
            'name': name,
            'sex': sex,
            'address': address,
            'phone': phone,
            'email': email,
            'contact_name': contact_name,
            'contact_phone': contact_phone,
            'contact_email': contact_email,
            'contact_relation': contact_relation,
            'suggested_id': generate_client_id()
        })
    
    # GET 请求：生成建议的客户ID
    suggested_id = generate_client_id()
    return render(request, "client/add_client.html", {'suggested_id': suggested_id})

def delete_client(request, client_id=None):
    # 如果是点击删除链接触发的逻辑
    if client_id:
        with connection.cursor() as cursor:
            cursor.execute("CALL delete_client(%s, @p_error)", [client_id])
            cursor.execute("SELECT @p_error")
            err = cursor.fetchone()[0]

            if err and "销户失败" in err:
                # 关键修复：把错误信息存入 messages 或者传给渲染上下文
                messages.error(request, err)
                # 失败后，跳回详情页，让用户在详情页看到报错
                return redirect(reverse("banksystem:detail_client", kwargs={'client_id': client_id}))
            else:
                messages.success(request, "客户删除成功")
                return redirect(reverse("banksystem:client"))
    
    return render(request, "client/delete_client.html")

def modify_client(request):
    if request.method == 'POST':
        client_id = request.POST.get('client_id')
        id_number = request.POST.get('id')
        name = request.POST.get('name')
        sex = request.POST.get('sex')
        address = request.POST.get('address')
        phone = request.POST.get('phone')
        email = request.POST.get('email')
        contact_name = request.POST.get('contact_name')
        contact_phone = request.POST.get('contact_phone')
        contact_email = request.POST.get('contact_email')
        contact_relation = request.POST.get('contact_relation')

        errors = {}

        if not client_id:
            errors['client_id'] = 'Client ID cannot be empty.'
        
        if not errors:
            with connection.cursor() as cursor:
                err = ''
                cursor.callproc('modify_client', [
                    client_id, id_number or None, name or None, sex or None,
                    address or None, phone or None, email or None, 
                    contact_name or None, contact_phone or None, 
                    contact_email or None, contact_relation or None, err
                ])
                cursor.execute('SELECT @_modify_client_11')
                err = cursor.fetchone()[0]
                if err:
                    errors['database'] = err

        if errors:
            return render(request, "client/modify_client.html", {"errors": errors})
        else:
            return redirect(reverse("banksystem:client"))

    return render(request, "client/modify_client.html")

def search_client(request):
    results = []
    has_searched = False
    query_params = {}

    if request.method == 'POST':
        has_searched = True

        # 获取前端传来的值，并去除首尾空格
        client_id = request.POST.get('client_id', '').strip()
        client_name = request.POST.get('client_name', '').strip()
        client_id_card = request.POST.get('client_id_card', '').strip()
        client_phone = request.POST.get('client_phone', '').strip()
        contact_name = request.POST.get('contact_name', '').strip()

        # 用于回显到页面，让输入框不清空
        query_params = {
            'client_id': client_id,
            'client_name': client_name,
            'client_id_card': client_id_card,
            'client_phone': client_phone,
            'contact_name': contact_name
        }

        with connection.cursor() as cursor:
            # 基础 SQL：1=1 是为了方便后面动态拼接 AND 语句
            query = "SELECT * FROM client WHERE 1=1"
            params = []

            # 只有当用户输入了对应内容时，才将其加入查询条件，并使用 LIKE 进行前后模糊匹配
            if client_id:
                query += " AND client_id LIKE %s"
                params.append(f"%{client_id}%")
            
            if client_name:
                query += " AND name LIKE %s"
                params.append(f"%{client_name}%")
                
            if client_id_card:
                query += " AND id LIKE %s"  # 数据库中身份证字段名为 id
                params.append(f"%{client_id_card}%")
                
            if client_phone:
                query += " AND phone LIKE %s"
                params.append(f"%{client_phone}%")
                
            if contact_name:
                query += " AND contact_name LIKE %s"
                params.append(f"%{contact_name}%")

            # 执行动态构建的 SQL 语句
            cursor.execute(query, params)
            results = cursor.fetchall()

    return render(request, "client/search_client.html", {
        "results": results,
        "has_searched": has_searched,
        "query_params": query_params
    })
def client_detail(request, client_id):
    # 获取客户基础信息
    with connection.cursor() as cursor:
        cursor.callproc('get_client_detail', [client_id])
        result = cursor.fetchall()
    
    client = result[0] if result else None
    
    # 新增：获取名下所有账户信息
    accounts = []
    if client:
        with connection.cursor() as cursor:
            # 获取储蓄账户
            cursor.execute("""
                SELECT account_id, bank_name, balance, open_date, rate as extra_info, 'saving' as acc_type 
                FROM saving_account WHERE client_id = %s
            """, [client_id])
            saving_accounts = cursor.fetchall()
            
            # 获取信用账户
            cursor.execute("""
                SELECT account_id, bank_name, balance, open_date, overdraft as extra_info, 'credit' as acc_type 
                FROM credit_account WHERE client_id = %s
            """, [client_id])
            credit_accounts = cursor.fetchall()
            
            accounts = list(saving_accounts) + list(credit_accounts)

    return render(request, "client/client_detail.html", {
        "client": client,
        "accounts": accounts  # 传递账户信息到模板
    })

def delete_client_detail(request, client_id=None):
    # 如果是点击删除链接触发的逻辑
    if client_id:
        with connection.cursor() as cursor:
            cursor.execute("CALL delete_client(%s, @p_error)", [client_id])
            cursor.execute("SELECT @p_error")
            err = cursor.fetchone()[0]

            if err and "销户失败" in err:
                # 关键修复：把错误信息存入 messages 或者传给渲染上下文
                messages.error(request, err)
                # 失败后，跳回详情页，让用户在详情页看到报错
                return redirect(reverse("banksystem:detail_client", kwargs={'client_id': client_id}))
            else:
                messages.success(request, "客户删除成功")
                return redirect(reverse("banksystem:client"))
    
    return render(request, "client/delete_client.html")
def modify_client_detail(request, client_id):
    # 查询客户信息
    with connection.cursor() as cursor:
        cursor.execute("SELECT * FROM client WHERE client_id = %s", [client_id])
        client = cursor.fetchone()
    
    if not client:
        return HttpResponseNotFound("Client not found")
    
    # client 元组顺序：
    # 0:client_id, 1:id, 2:name, 3:sex, 4:address, 5:phone, 6:email,
    # 7:contact_name, 8:contact_phone, 9:contact_email, 10:contact_relation
    
    if request.method == 'POST':
        # 获取表单数据
        name = request.POST.get('name')
        sex = request.POST.get('sex')
        address = request.POST.get('address')
        phone = request.POST.get('phone')
        email = request.POST.get('email')
        contact_name = request.POST.get('contact_name')
        contact_phone = request.POST.get('contact_phone')
        contact_email = request.POST.get('contact_email')
        contact_relation = request.POST.get('contact_relation')
        
        has_error = False
        
        # 验证姓名
        if not name:
            messages.error(request, '❌ 姓名不能为空')
            has_error = True
        
        # 验证性别
        if sex not in ['男', '女']:
            messages.error(request, '❌ 请选择性别')
            has_error = True
        
        # 验证地址
        if not address:
            messages.error(request, '❌ 地址不能为空')
            has_error = True
        
        # 验证手机号
        if phone:
            if len(phone) != 11:
                messages.error(request, '❌ 手机号格式错误：应为11位数字')
                has_error = True
            elif not phone.isdigit():
                messages.error(request, '❌ 手机号格式错误：只能包含数字')
                has_error = True
            elif phone[0] != '1':
                messages.error(request, '❌ 手机号格式错误：应以1开头')
                has_error = True
        else:
            messages.error(request, '❌ 手机号不能为空')
            has_error = True
        
        # 验证邮箱
        if email and ('@' not in email or '.' not in email):
            messages.error(request, '❌ 邮箱格式错误')
            has_error = True
        
        # 验证联系人姓名
        if not contact_name:
            messages.error(request, '❌ 联系人姓名不能为空')
            has_error = True
        
        # 验证联系人电话
        if not contact_phone:
            messages.error(request, '❌ 联系人电话不能为空')
            has_error = True
        else:
            if len(contact_phone) < 8 or len(contact_phone) > 11:
                messages.error(request, '❌ 联系人电话格式错误：应为8-11位')
                has_error = True
            elif not contact_phone.isdigit():
                messages.error(request, '❌ 联系人电话格式错误：只能包含数字')
                has_error = True
        
        # 验证联系人关系
        if not contact_relation:
            messages.error(request, '❌ 联系人关系不能为空')
            has_error = True
        
        # 验证联系人邮箱
        if contact_email and ('@' not in contact_email or '.' not in contact_email):
            messages.error(request, '❌ 联系人邮箱格式错误')
            has_error = True
        
        if not has_error:
            try:
                with connection.cursor() as cursor:
                    cursor.execute("""
                        UPDATE client 
                        SET name=%s, sex=%s, address=%s, phone=%s, email=%s,
                            contact_name=%s, contact_phone=%s, contact_email=%s, contact_relation=%s
                        WHERE client_id=%s
                    """, [name, sex, address, phone, email, contact_name, contact_phone, contact_email, contact_relation, client_id])
                messages.success(request, f'✅ 客户 "{name}" 信息更新成功！')
                return redirect(reverse('banksystem:detail_client', kwargs={'client_id': client_id}))
            except Exception as e:
                messages.error(request, f'更新客户信息时出错：{str(e)}')
                has_error = True
        
        # 有错误时返回表单，保留用户输入
        updated_client = [
            client_id,           # 0
            client[1],           # 1 身份证号（不可改）
            name if name else client[2],           # 2 姓名
            sex if sex else client[3],             # 3 性别 ← 关键
            address if address else client[4],     # 4 地址
            phone if phone else client[5],         # 5 电话
            email if email else client[6],         # 6 邮箱
            contact_name if contact_name else client[7],      # 7 联系人姓名
            contact_phone if contact_phone else client[8],    # 8 联系人电话
            contact_email if contact_email else client[9],    # 9 联系人邮箱
            contact_relation if contact_relation else client[10]  # 10 联系人关系
        ]
        return render(request, 'client/modify_client_detail.html', {'client': updated_client})
    
    # GET 请求：直接返回查询到的客户信息
    return render(request, 'client/modify_client_detail.html', {'client': client})

# 账户管理
def create_credit(request):
    # 获取所有银行列表供下拉选择
    with connection.cursor() as cursor:
        cursor.execute("SELECT bank_name FROM Bank")
        banks = cursor.fetchall()
    
    # 获取所有客户列表供下拉选择
    with connection.cursor() as cursor:
        cursor.execute("SELECT client_id, name FROM client ORDER BY client_id")
        clients = cursor.fetchall()
    
    # 自动生成信用账户ID
    def generate_credit_account_id():
        with connection.cursor() as cursor:
            cursor.execute("SELECT account_id FROM credit_account ORDER BY account_id DESC LIMIT 1")
            last_id = cursor.fetchone()
            if last_id and last_id[0]:
                last_num = int(last_id[0][2:])
                new_num = last_num + 1
                return f"CA{new_num:03d}"
            else:
                return "CA001"
    
    if request.method == 'POST':
        account_id = request.POST.get('account_id')
        if not account_id:
            account_id = generate_credit_account_id()
        
        bank_name = request.POST.get('bank_name')
        balance = request.POST.get('balance')
        open_date = request.POST.get('open_date')
        overdraft = request.POST.get('overdraft')
        client_id = request.POST.get('client_id')
        
        has_error = False
        import re
        
        # 验证账户ID格式（如果是用户手动填写的）
        if request.POST.get('account_id'):
            if not re.match(r'^CA\d{3}$', account_id):
                messages.error(request, '❌ 账户ID格式错误：应为 CA + 3位数字，如：CA001')
                has_error = True
        
        # 验证账户ID是否已存在
        if not has_error:
            with connection.cursor() as cursor:
                cursor.execute("SELECT COUNT(*) FROM credit_account WHERE account_id = %s", [account_id])
                if cursor.fetchone()[0] > 0:
                    messages.error(request, f'❌ 账户ID "{account_id}" 已存在，请使用其他ID')
                    has_error = True
        
        # 验证客户ID是否存在（添加友好错误提示）
        if not has_error:
            with connection.cursor() as cursor:
                cursor.execute("SELECT COUNT(*) FROM client WHERE client_id = %s", [client_id])
                if cursor.fetchone()[0] == 0:
                    messages.error(request, f'❌ 客户ID "{client_id}" 不存在，请先创建客户或输入正确的客户ID')
                    has_error = True
        
        # 验证余额
        if not has_error:
            try:
                balance_float = float(balance)
                if balance_float < 0:
                    messages.error(request, '❌ 余额不能为负数')
                    has_error = True
            except ValueError:
                messages.error(request, '❌ 余额格式错误，请输入数字')
                has_error = True
        
        # 验证透支额度
        if not has_error:
            try:
                overdraft_float = float(overdraft)
                if overdraft_float < 0:
                    messages.error(request, '❌ 透支额度不能为负数')
                    has_error = True
            except ValueError:
                messages.error(request, '❌ 透支额度格式错误，请输入数字')
                has_error = True
        
        if not has_error:
            try:
                with connection.cursor() as cursor:
                    cursor.callproc('create_credit_account', [account_id, bank_name, balance, open_date, overdraft, client_id])
                messages.success(request, f'✅ 信用账户 {account_id} 创建成功！')
                return redirect(reverse('banksystem:account'))
            except Exception as e:
                messages.error(request, f'❌ 创建失败：{str(e)}')
                has_error = True
        
        # 有错误时返回表单，保留用户输入
        suggested_id = generate_credit_account_id()
        return render(request, 'account/create_credit.html', {
            'banks': banks,
            'clients': clients,
            'suggested_id': suggested_id,
            'account_id': account_id,
            'bank_name': bank_name,
            'balance': balance,
            'open_date': open_date,
            'overdraft': overdraft,
            'client_id': client_id
        })
    
    suggested_id = generate_credit_account_id()
    return render(request, 'account/create_credit.html', {
        'banks': banks,
        'clients': clients,
        'suggested_id': suggested_id
    })

def create_saving(request):
    # 获取所有银行列表供下拉选择
    with connection.cursor() as cursor:
        cursor.execute("SELECT bank_name FROM Bank")
        banks = cursor.fetchall()
    
    # 获取所有客户列表供下拉选择
    with connection.cursor() as cursor:
        cursor.execute("SELECT client_id, name FROM client ORDER BY client_id")
        clients = cursor.fetchall()
    
    # 自动生成储蓄账户ID
    def generate_saving_account_id():
        with connection.cursor() as cursor:
            cursor.execute("SELECT account_id FROM saving_account ORDER BY account_id DESC LIMIT 1")
            last_id = cursor.fetchone()
            if last_id and last_id[0]:
                last_num = int(last_id[0][2:])
                new_num = last_num + 1
                return f"SA{new_num:03d}"
            else:
                return "SA001"
    
    if request.method == 'POST':
        account_id = request.POST.get('account_id')
        if not account_id:
            account_id = generate_saving_account_id()
        
        bank_name = request.POST.get('bank_name')
        balance = request.POST.get('balance')
        open_date = request.POST.get('open_date')
        rate = request.POST.get('rate')
        client_id = request.POST.get('client_id')
        
        has_error = False
        import re
        
        # 验证账户ID格式（如果是用户手动填写的）
        if request.POST.get('account_id'):
            if not re.match(r'^SA\d{3}$', account_id):
                messages.error(request, '❌ 账户ID格式错误：应为 SA + 3位数字，如：SA001')
                has_error = True
        
        # 验证账户ID是否已存在
        if not has_error:
            with connection.cursor() as cursor:
                cursor.execute("SELECT COUNT(*) FROM saving_account WHERE account_id = %s", [account_id])
                if cursor.fetchone()[0] > 0:
                    messages.error(request, f'❌ 账户ID "{account_id}" 已存在，请使用其他ID')
                    has_error = True
        
        # 验证客户ID是否存在（友好错误提示）
        if not has_error:
            with connection.cursor() as cursor:
                cursor.execute("SELECT COUNT(*) FROM client WHERE client_id = %s", [client_id])
                if cursor.fetchone()[0] == 0:
                    messages.error(request, f'❌ 客户ID "{client_id}" 不存在，请先创建客户或输入正确的客户ID')
                    has_error = True
        
        # 验证余额
        if not has_error:
            try:
                balance_float = float(balance)
                if balance_float < 0:
                    messages.error(request, '❌ 余额不能为负数')
                    has_error = True
            except ValueError:
                messages.error(request, '❌ 余额格式错误，请输入数字')
                has_error = True
        
        # 验证利率
        if not has_error:
            try:
                rate_float = float(rate)
                if rate_float < 0:
                    messages.error(request, '❌ 利率不能为负数')
                    has_error = True
            except ValueError:
                messages.error(request, '❌ 利率格式错误，请输入数字')
                has_error = True
        
        if not has_error:
            try:
                with connection.cursor() as cursor:
                    cursor.callproc('create_saving_account', [account_id, bank_name, balance, open_date, rate, client_id])
                messages.success(request, f'✅ 储蓄账户 {account_id} 创建成功！')
                return redirect(reverse('banksystem:account'))
            except Exception as e:
                messages.error(request, f'❌ 创建失败：{str(e)}')
                has_error = True
        
        # 有错误时返回表单，保留用户输入
        suggested_id = generate_saving_account_id()
        return render(request, 'account/create_saving.html', {
            'banks': banks,
            'clients': clients,
            'suggested_id': suggested_id,
            'account_id': account_id,
            'bank_name': bank_name,
            'balance': balance,
            'open_date': open_date,
            'rate': rate,
            'client_id': client_id
        })
    
    suggested_id = generate_saving_account_id()
    return render(request, 'account/create_saving.html', {
        'banks': banks,
        'clients': clients,
        'suggested_id': suggested_id
    })

# 查看账户信息
def view_account(request, account_id, account_type):
    with connection.cursor() as cursor:
        loans_info = []
        remaining_limit = 0
        
        if account_type == 'saving':
            # --- 【新增代码：强制补息】 ---
            # 在查询之前调用存储过程，确保余额包含最新利息
            cursor.callproc('ensure_saving_interest_up_to_date', [account_id])
            
            cursor.callproc('get_saving_account_by_id', [account_id])
            account = cursor.fetchone()
        else:
            # 信用账户逻辑保持不变
            cursor.callproc('get_credit_account_by_id', [account_id])
            account = cursor.fetchone()
            
            # 【信用账户专属逻辑】
            if account:
                client_id = account[6]
                bank_name = account[1]
                overdraft = float(account[5]) if account[5] else 0.0
                
                # 查询该账户下的贷款，并顺便对每笔贷款进行补息
                cursor.execute("""
                    SELECT loan_id FROM loan WHERE account_id = %s
                """, [account_id])
                loan_ids = cursor.fetchall()
                for l_id in loan_ids:
                    cursor.callproc('ensure_loan_interest_up_to_date', [l_id[0]])
                
                # 现在查询详细信息
                cursor.execute("""
                    SELECT 
                        loan_id, 
                        loan_money, 
                        loan_date, 
                        get_remaining_loan_amount(loan_id) AS remaining_amount
                    FROM loan
                    WHERE account_id = %s
                """, [account_id])
                
                raw_loans = cursor.fetchall()
                total_remaining_loan = 0 
                for l in raw_loans:
                    loan_money = float(l[1])
                    remaining = float(l[3])
                    paid = loan_money - remaining
                    total_remaining_loan += remaining 
                    loans_info.append({
                        'loan_id': l[0], 'loan_date': l[2], 'loan_money': loan_money,
                        'paid': paid, 'remaining': remaining
                    })
                remaining_limit = overdraft - total_remaining_loan

    return render(request, 'account/view_account.html', {
        'account': account, 
        'account_type': account_type,
        'loans_info': loans_info,
        'remaining_limit': remaining_limit
    })
def update_account(request, account_id, account_type):
    with connection.cursor() as cursor:
        if account_type == 'saving':
            cursor.execute("SELECT * FROM saving_account WHERE account_id = %s", [account_id])
            account = cursor.fetchone()
        else:
            cursor.execute("SELECT * FROM credit_account WHERE account_id = %s", [account_id])
            account = cursor.fetchone()
    
    if not account:
        return HttpResponseNotFound("Account not found")
    
    if request.method == 'POST':
        balance = request.POST.get('balance')
        has_error = False
        
        import re
        # 验证余额
        try:
            balance_float = float(balance)
            if balance_float < 0:
                messages.error(request, '❌ 余额不能为负数')
                has_error = True
        except ValueError:
            messages.error(request, '❌ 余额格式错误，请输入数字')
            has_error = True
        
        if account_type == 'saving':
            rate = request.POST.get('rate')
            try:
                rate_float = float(rate)
                if rate_float < 0:
                    messages.error(request, '❌ 利率不能为负数')
                    has_error = True
            except ValueError:
                messages.error(request, '❌ 利率格式错误，请输入数字')
                has_error = True
            
            if not has_error:
                try:
                    with connection.cursor() as cursor:
                        cursor.callproc('update_saving_account_by_account_id', [account_id, account[1], balance, rate])
                    messages.success(request, f'✅ 储蓄账户 {account_id} 修改成功！')
                except Exception as e:
                    messages.error(request, f'❌ 修改失败：{str(e)}')
                    has_error = True
        
        else:  # credit account
            overdraft = request.POST.get('overdraft')
            try:
                overdraft_float = float(overdraft)
                if overdraft_float < 0:
                    messages.error(request, '❌ 透支额度不能为负数')
                    has_error = True
            except ValueError:
                messages.error(request, '❌ 透支额度格式错误，请输入数字')
                has_error = True
            
            if not has_error:
                try:
                    with connection.cursor() as cursor:
                        cursor.callproc('update_credit_account_by_account_id', [account_id, account[1], balance, overdraft])
                    messages.success(request, f'✅ 信用账户 {account_id} 修改成功！')
                except Exception as e:
                    messages.error(request, f'❌ 修改失败：{str(e)}')
                    has_error = True
        
        if has_error:
            return render(request, 'account/update_account.html', {
                'account_id': account_id,
                'account_type': account_type,
                'account': account
            })
        
        return redirect(reverse('banksystem:view_account', kwargs={'account_id': account_id, 'account_type': account_type}))
    
    return render(request, 'account/update_account.html', {
        'account_id': account_id,
        'account_type': account_type,
        'account': account
    })

def delete_account(request, account_id, account_type):
    try:
        with connection.cursor() as cursor:
            if account_type == 'saving':
                cursor.callproc('delete_saving_account_by_account_id', [account_id])
            else:
                cursor.callproc('delete_credit_account_by_account_id', [account_id])
        messages.success(request, 'Account deleted successfully')
        print('Account deleted successfully')
    except Exception as e:
        messages.error(request, 'Error deleting account: ' + str(e))
        print('Error deleting account: ' + str(e))
    return redirect(reverse('banksystem:account'))

def search_account(request):
    results = []
    if request.method == 'POST':
        account_id = request.POST.get('account_id', None)
        bank_name = request.POST.get('bank_name', None)
        name = request.POST.get('name', None)
        client_id = request.POST.get('client_id', None)
        print(account_id, bank_name, name, client_id)
        with connection.cursor() as cursor:
            cursor.callproc('search_saving_account', [client_id, account_id, bank_name, name])
            saving_accounts = cursor.fetchall()
        with connection.cursor() as cursor:
            cursor.callproc('search_credit_account', [client_id, account_id, bank_name, name])
            credit_accounts = cursor.fetchall()
        results = saving_accounts + credit_accounts
        print(results)
    return render(request, "account/search_account.html", {"results": results})

# 银行信息管理
def add_bank(request):
    if request.method == 'POST':
        bank_name = request.POST.get('bank_name')
        location = request.POST.get('location')
        asset = request.POST.get('asset')
        
        # 读取图像文件
        image_file = request.FILES.get('image')
        image_url = None
        if image_file:
            # 生成图片文件名
            image_name = f"images/{bank_name.replace(' ', '_').lower()}.jpg"
            # 保存文件
            image_path = default_storage.save(image_name, ContentFile(image_file.read()))
            # 获取文件的 URL
            image_url = f"/media/{image_path}"
        try:
            with connection.cursor() as cursor:
                cursor.execute("CALL AddBank(%s, %s, %s, %s)", [bank_name, location, asset, image_url])
            messages.success(request, "Bank added successfully")
        except Exception as e:
            messages.error(request, "添加银行时出错: " + str(e))
        return redirect(reverse('banksystem:bankinfo'))
    
    return render(request, 'bankinfo/add_bank.html')

def update_bank(request, bank_name):
    if request.method == 'POST':
        location = request.POST['location']
        asset = request.POST['asset']
        
        # 读取图像文件
        image_file = request.FILES.get('image')
        image_url = None
        if image_file:
            image_name = f"images/{bank_name.replace(' ', '_').lower()}.jpg"
            image_path = default_storage.save(image_name, ContentFile(image_file.read()))
            image_url = f"/media/{image_path}"
        
        try:
            with connection.cursor() as cursor:
                if image_url:
                    cursor.execute(
                        "UPDATE Bank SET location = %s, asset = %s, image = %s WHERE bank_name = %s",
                        [location, asset, image_url, bank_name]
                    )
                else:
                    cursor.execute(
                        "UPDATE Bank SET location = %s, asset = %s WHERE bank_name = %s",
                        [location, asset, bank_name]
                    )
            
            # 添加成功消息
            messages.success(request, f'✅ 银行 "{bank_name}" 信息更新成功！')
            
        except Exception as e:
            messages.error(request, f'❌ 更新银行信息时出错：{str(e)}')
        
        return redirect('banksystem:bankinfo')
    
    with connection.cursor() as cursor:
        cursor.execute("SELECT bank_name, location, asset, image FROM Bank WHERE bank_name = %s", [bank_name])
        row = cursor.fetchone()
        bank = row if row else None
    
    return render(request, 'bankinfo/update_bank.html', {'bank': bank})
def delete_bank(request, bank_name):
    try:
        with connection.cursor() as cursor:
            cursor.execute("CALL DeleteBank(%s)", [bank_name])
        messages.success(request, '银行删除成功！')
    except Exception as e:
        messages.error(request, '删除银行时出错：' + str(e))
    
    return redirect('banksystem:bankinfo')

def search_bank(request):
    results = []
    if request.method == 'POST':
        bank_name = request.POST.get('bank_name', None)
        location = request.POST.get('location', None)

        with connection.cursor() as cursor:
            cursor.callproc('search_bank', [bank_name, location])
            results = cursor.fetchall()
    return render(request, "bankinfo/search_bank.html", {"results": results})

def get_bank_info(request, bank_name):
    with connection.cursor() as cursor:
        cursor.callproc('search_bank', [bank_name, None])
        results = cursor.fetchall()
    with connection.cursor() as cursor:
        cursor.callproc('get_departments_by_bank', [bank_name])
        departments = cursor.fetchall()
    print(departments)
    return render(request, 'bankinfo/bank_info.html', {'results':results, 'departments': departments})

def add_department(request, bank_name):
    if request.method == 'POST':
        department_id = request.POST.get('department_id')
        department_name = request.POST.get('department_name')
        department_type = request.POST.get('department_type')
        
        # 获取银行前缀映射
        bank_prefix_map = {
            '福州银行': 'FZ', '厦门银行': 'XM', '泉州银行': 'QZ',
            '莆田银行': 'PT', '漳州银行': 'ZZ', '龙岩银行': 'LY',
            '三明银行': 'SM', '南平银行': 'NP', '宁德银行': 'ND'
        }
        expected_prefix = bank_prefix_map.get(bank_name, '')
        
        # 验证部门ID长度（5位：2字母+3数字）
        if len(department_id) != 5:
            messages.error(request, '部门ID长度应为5位字符（银行前缀2字母 + 3位数字，如：SM001）')
            return render(request, 'bankinfo/add_department.html', {'bank_name': bank_name})
        
        # 验证格式：前2位是字母，后3位是数字
        if not (department_id[:2].isalpha() and department_id[2:].isdigit()):
            messages.error(request, '部门ID格式错误：前2位应为字母（银行前缀），后3位应为数字，如：SM001')
            return render(request, 'bankinfo/add_department.html', {'bank_name': bank_name})
        
        # 验证前缀是否匹配银行
        if expected_prefix and department_id[:2] != expected_prefix:
            messages.error(request, f'部门ID前缀应为 "{expected_prefix}"（{bank_name}的前缀），您输入的是 "{department_id[:2]}"')
            return render(request, 'bankinfo/add_department.html', {'bank_name': bank_name})
        
        try:
            with connection.cursor() as cursor:
                cursor.callproc('add_department', [department_id, bank_name, department_name, department_type])
            messages.success(request, f'部门 "{department_name}" 添加成功！')
            return redirect(reverse('banksystem:bank_info', kwargs={'bank_name': bank_name}))
            
        except Exception as e:
          error_msg = str(e)
          print(f"DEBUG: 错误信息 = {error_msg}")
    
          if 'DUPLICATE_ID' in error_msg:
              messages.error(request, f'添加失败：部门ID "{department_id}" 已存在，请使用其他ID')
          elif 'DUPLICATE_NAME' in error_msg:
              messages.error(request, f'添加失败：部门名称 "{department_name}" 在该银行下已存在')  # 这个已经是正确的
          else:
              messages.error(request, f'添加失败：{error_msg}')
            
        return render(request, 'bankinfo/add_department.html', {'bank_name': bank_name})
    
    return render(request, 'bankinfo/add_department.html', {'bank_name': bank_name})

def delete_department(request, bank_name, department_id):
    with connection.cursor() as cursor:
        cursor.callproc('delete_department', [department_id])
    return redirect(reverse('banksystem:bank_info', kwargs={'bank_name': bank_name}))

def update_department(request, bank_name, department_id):
    if request.method == 'POST':
        department_name = request.POST.get('department_name')
        department_type = request.POST.get('department_type')
        
        try:
            with connection.cursor() as cursor:
                cursor.callproc('update_department', [department_id, department_name, department_type])
            messages.success(request, f'✅ 部门 "{department_name}" 信息更新成功！')
        except Exception as e:
            messages.error(request, f'❌ 更新部门信息时出错：{str(e)}')
        
        return redirect(reverse('banksystem:bank_info', kwargs={'bank_name': bank_name}))
    else:
        with connection.cursor() as cursor:
            cursor.callproc('get_department_by_id', [department_id])
            department_info = cursor.fetchone()
        return render(request, 'bankinfo/update_department.html', {
            'department_id': department_info[0],
            'department_name': department_info[2],
            'department_type': department_info[3],
            'bank_name': bank_name
        })

def search_department(request, bank_name):
    results = []
    if request.method == 'POST':
        department_id = request.POST.get('department_id', None)
        department_name = request.POST.get('department_name', None)

        with connection.cursor() as cursor:
            print(department_id, department_name)
            cursor.callproc('search_department', [department_id, department_name, bank_name])
            results = cursor.fetchall()
            print(results)
    return render(request, "bankinfo/search_department.html", {"bank_name": bank_name, "departments": results})

# 员工信息管理

def get_employees_by_department(request, bank_name, department_id):
    employees = []
    if request.method == 'GET':
        with connection.cursor() as cursor:
            cursor.callproc('get_employee_by_department_id', [department_id])
            employees = cursor.fetchall()
    return render(request, 'bankinfo/employee_list.html', {'bank_name': bank_name, 'department_id':department_id, 'employees': employees})

def validate_id_number(id_num):
    """验证身份证号（18位，最后一位可能是数字或X）"""
    if not id_num or len(id_num) != 18:
        return False
    # 前17位必须是数字
    if not id_num[:17].isdigit():
        return False
    # 最后一位是数字或X/x
    if not (id_num[17].isdigit() or id_num[17].upper() == 'X'):
        return False
    return True

# 验证手机号（11位数字，以1开头）
def validate_phone(phone):
    if not phone:
        return False
    if len(phone) != 11:
        return False
    if not phone.isdigit():
        return False
    if phone[0] != '1':
        return False
    return True

def add_employee(request, bank_name, department_id):
    # 自动生成员工ID
    def generate_employee_id():
        with connection.cursor() as cursor:
            cursor.execute("SELECT employee_id FROM employee ORDER BY employee_id DESC LIMIT 1")
            last_id = cursor.fetchone()
            if last_id and last_id[0] and last_id[0][1:].isdigit():
                return f"E{int(last_id[0][1:]) + 1:03d}"
            return "E001"

    form_data = {
        'employee_id': '',
        'id_number': '',
        'name': '',
        'sex': '',
        'phone': '',
        'address': '',
        'start_work_date': '',
        'bank_name': bank_name,
        'department_id': department_id,
        'suggested_id': generate_employee_id()
    }
    
    if request.method == 'POST':
        employee_id = request.POST.get('employee_id', '').strip()
        if not employee_id:
            employee_id = generate_employee_id()

        id_number = request.POST.get('id_card', '')
        name = request.POST.get('employee_name', '')
        sex = request.POST.get('sex', '')
        # print(f"【调试-前端提交的性别】: {sex}")
        phone = request.POST.get('phone', '')
        address = request.POST.get('address', '')
        start_work_date = request.POST.get('start_work_date', '')
        
        # 保存用户输入的数据，用于页面回显
        form_data = {
            'employee_id': employee_id,
            'id_number': id_number,
            'name': name,
            'sex': sex,
            'phone': phone,
            'address': address,
            'start_work_date': start_work_date,
            'bank_name': bank_name,
            'department_id': department_id,
            'suggested_id': generate_employee_id()
        }
        
        import re
        has_error = False
        
        # 验证员工ID格式（仅当用户手动填写时）
        if request.POST.get('employee_id', '').strip():
            if not re.match(r'^E\d{3}$', employee_id):
                messages.error(request, '❌ 员工ID格式错误：应为 E + 3位数字，如：E001')
                has_error = True

        if not validate_id_number(id_number):
            messages.error(request, '❌ 身份证号格式错误：请输入合法的18位身份证号')
            has_error = True
        
        # 验证手机号（使用外层的 validate_phone 函数）
        if not validate_phone(phone):
            messages.error(request, '❌ 手机号格式错误：请输入11位手机号')
            has_error = True
        
        
        # 验证员工ID在同一个银行下是否重复（只有格式正确时才检查）
        if not has_error and employee_id:
            try:
                with connection.cursor() as cursor:
                    cursor.execute("""
                        SELECT COUNT(*) FROM employee e 
                        JOIN department d ON e.department_id = d.department_id 
                        WHERE d.bank_name = %s AND e.employee_id = %s
                    """, [bank_name, employee_id])
                    count = cursor.fetchone()[0]
                    if count > 0:
                        messages.error(request, f'❌ 员工ID "{employee_id}" 在该银行下已存在，请使用其他ID')
                        has_error = True
            except Exception as e:
                messages.error(request, f'验证员工ID时出错：{str(e)}')
                has_error = True
        
        # 如果没有错误，才执行添加
        if not has_error:
            try:
                with connection.cursor() as cursor:
                    cursor.callproc('add_employee', [employee_id, department_id, id_number, name, sex, phone, address, start_work_date])
        
        # 成功：直接返回员工列表页面，并带上成功消息
                with connection.cursor() as cursor:
                    cursor.callproc('get_employee_by_department_id', [department_id])
                    employees = cursor.fetchall()
        
                success_message = f'✅ 员工 "{name}" 添加成功！'
                return render(request, 'bankinfo/employee_list.html', {
                  'bank_name': bank_name,
                  'department_id': department_id,
                  'employees': employees,
                  'success_message': success_message  # 直接传递消息
              })
            except Exception as e:
                error_msg = str(e)
                if 'DUPLICATE_ID' in error_msg:
                     messages.error(request, f'❌ 员工ID "{employee_id}" 已存在，请使用其他ID')
                else:
                     messages.error(request, f'添加员工时出错：{error_msg}')
                return render(request, 'bankinfo/add_employee.html', form_data)
        
        # 有错误时，返回表单页面并保留输入
        return render(request, 'bankinfo/add_employee.html', form_data)
    
    # GET 请求
    return render(request, 'bankinfo/add_employee.html', form_data)

def delete_employee(request, bank_name, department_id, employee_id):
    with connection.cursor() as cursor:
        cursor.callproc('delete_employee', [employee_id])
    return redirect(reverse('banksystem:employee_list', kwargs={'bank_name': bank_name, 'department_id': department_id}))

def update_employee(request, bank_name, department_id, employee_id):
    # GET 请求：显示表单
    if request.method == 'GET':
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT employee_id, id, name, sex, phone, address, start_work_date 
                FROM employee WHERE employee_id = %s
            """, [employee_id])
            employee_info = cursor.fetchone()
        
        if not employee_info:
            messages.error(request, '员工不存在')
            return redirect(reverse('banksystem:employee_list', kwargs={'bank_name': bank_name, 'department_id': department_id}))
        
        return render(request, 'bankinfo/update_employee.html', {
            'employee_id': employee_info[0],
            'id_number': employee_info[1],
            'name': employee_info[2],
            'sex': employee_info[3],
            'phone': employee_info[4],
            'address': employee_info[5],
            'start_work_date': employee_info[6],
            'bank_name': bank_name,
            'department_id': department_id
        })
    
    # POST 请求：处理修改
    if request.method == 'POST':
        name = request.POST.get('name')
        phone = request.POST.get('phone')
        address = request.POST.get('address')
        
        # 先查询员工原信息
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT employee_id, id, name, sex, phone, address, start_work_date 
                FROM employee WHERE employee_id = %s
            """, [employee_id])
            original = cursor.fetchone()
        
        if not original:
            messages.error(request, '员工不存在')
            return redirect(reverse('banksystem:employee_list', kwargs={'bank_name': bank_name, 'department_id': department_id}))
        
        original_employee_id, original_id, original_name, original_sex, original_phone, original_address, original_start_work_date = original
        
        # 准备返回的表单数据
        context = {
            'employee_id': original_employee_id,
            'id_number': original_id,
            'name': name if name else original_name,
            'sex': original_sex,
            'phone': phone if phone else original_phone,
            'address': address if address else original_address,
            'start_work_date': original_start_work_date,
            'bank_name': bank_name,
            'department_id': department_id
        }
        
        import re
        has_error = False
        
        # 验证手机号（如果修改了）
        if phone and phone != original_phone:
            if not re.match(r'^1[3-9]\d{9}$', phone):
                messages.error(request, '❌ 手机号格式错误：请输入11位手机号')
                has_error = True
        
        # 验证姓名（如果修改了）
        if name and name != original_name:
            if not name or len(name.strip()) == 0:
                messages.error(request, '❌ 姓名不能为空')
                has_error = True
        
        # 如果有错误，返回修改页面并显示错误
        if has_error:
            return render(request, 'bankinfo/update_employee.html', context)
        
        # 没有错误，执行更新
        # 如果字段为空，使用原值；否则使用新值
        final_name = name if name else original_name
        final_phone = phone if phone else original_phone
        final_address = address if address else original_address
        
        try:
            with connection.cursor() as cursor:
                cursor.execute("""
                    UPDATE employee 
                    SET name = %s, phone = %s, address = %s 
                    WHERE employee_id = %s
                """, [final_name, final_phone, final_address, employee_id])
            messages.success(request, f'✅ 员工 "{final_name}" 信息更新成功！')
        except Exception as e:
            messages.error(request, f'更新员工信息时出错：{str(e)}')
            return render(request, 'bankinfo/update_employee.html', context)
        
        return redirect(reverse('banksystem:employee_list', kwargs={'bank_name': bank_name, 'department_id': department_id}))

def search_employee(request, bank_name, department_id):
    results = []
    if request.method == 'POST':
        employee_id = request.POST.get('employee_id', None)
        name = request.POST.get('name', None)

        with connection.cursor() as cursor:
            cursor.callproc('search_employee', [employee_id, name, department_id])
            results = cursor.fetchall()
    return render(request, "bankinfo/search_employee.html", {"bank_name": bank_name, "department_id": department_id, "employees": results})


# 贷款管理

# 查看贷款具体信息
def view_loan(request, loan_id):
    with connection.cursor() as cursor:
        cursor.callproc('get_loan_by_id', [loan_id])
        loan = cursor.fetchone()
    print(loan)
    return render(request, 'loan/view_loan.html', {'loan': loan})

def add_loan(request):
    # 获取所有银行列表供下拉选择
    with connection.cursor() as cursor:
        cursor.execute("SELECT bank_name FROM Bank")
        banks = cursor.fetchall()
    
    # 获取所有客户列表供下拉选择
    with connection.cursor() as cursor:
        cursor.execute("SELECT client_id, name FROM client ORDER BY client_id")
        clients = cursor.fetchall()
    
    # 【核心修改点】：获取所有信用账户，并使用子查询动态计算出“可用剩余额度 (remaining_limit)”
   # ===== 找到 views.py 中的这部分，直接替换成以下代码 =====
    # 【核心修复】：修改查询，只关联计算特定 account_id 下的贷款金额
    import json
    with connection.cursor() as cursor:
        cursor.execute("""
            SELECT 
                ca.account_id, 
                ca.bank_name, 
                ca.balance, 
                ca.overdraft, 
                ca.client_id,
                -- 核心逻辑：这里必须使用 ca.account_id 进行精准匹配，而不是 client_id
                (ca.overdraft - COALESCE((
                    SELECT SUM(get_remaining_loan_amount(l.loan_id))
                    FROM loan l
                    WHERE l.account_id = ca.account_id 
                ), 0)) AS remaining_limit
            FROM credit_account ca
        """)
        rows = cursor.fetchall()
        
    credit_accounts_json = json.dumps([
        {
            'account_id': r[0], 
            'bank_name': r[1], 
            'balance': str(r[2]), 
            'overdraft': str(r[3]),      # 修正：这是原透支额度
            'client_id': r[4],
            'remaining_limit': str(r[5]) # 修正：这是计算出的实际可用额度
        }
        for r in rows
    ])
    # 自动生成贷款ID
    def generate_loan_id():
        with connection.cursor() as cursor:
            cursor.execute("SELECT loan_id FROM loan ORDER BY loan_id DESC LIMIT 1")
            last_id = cursor.fetchone()
            if last_id and last_id[0]:
                last_num = int(last_id[0][1:])  # L001 -> 1
                new_num = last_num + 1
                return f"L{new_num:03d}"  # L001, L002...
            else:
                return "L001"
    
    if request.method == 'POST':
        loan_id = request.POST.get('loan_id')
        if not loan_id:
            loan_id = generate_loan_id()
        
        client_id = request.POST.get('client_id')
        bank_name = request.POST.get('bank_name')
        loan_money = request.POST.get('loan_money')
        loan_rate = request.POST.get('loan_rate')
        loan_date = request.POST.get('loan_date')
        account_id = request.POST.get('credit_account_ref')
        if not account_id:
            account_id = None
        has_error = False
        import re
        
        # 验证贷款ID格式（如果是用户手动填写的）
        if request.POST.get('loan_id'):
            if not re.match(r'^L\d{3}$', loan_id):
                messages.error(request, '❌ 贷款ID格式错误：应为 L + 3位数字，如：L001')
                has_error = True
        
        # 验证贷款ID是否已存在
        if not has_error:
            with connection.cursor() as cursor:
                cursor.execute("SELECT COUNT(*) FROM loan WHERE loan_id = %s", [loan_id])
                if cursor.fetchone()[0] > 0:
                    messages.error(request, f'❌ 贷款ID "{loan_id}" 已存在，请使用其他ID')
                    has_error = True
        
        # 验证客户ID是否存在
        if not has_error:
            with connection.cursor() as cursor:
                cursor.execute("SELECT COUNT(*) FROM client WHERE client_id = %s", [client_id])
                if cursor.fetchone()[0] == 0:
                    messages.error(request, f'❌ 客户ID "{client_id}" 不存在，请先创建客户或输入正确的客户ID')
                    has_error = True
        
        # 验证贷款金额
        if not has_error:
            try:
                loan_money_float = float(loan_money)
                if loan_money_float <= 0:
                    messages.error(request, '❌ 贷款金额必须大于0')
                    has_error = True
            except ValueError:
                messages.error(request, '❌ 贷款金额格式错误，请输入数字')
                has_error = True
        
        # 验证贷款利率
        if not has_error:
            try:
                loan_rate_float = float(loan_rate)
                if loan_rate_float < 0:
                    messages.error(request, '❌ 贷款利率不能为负数')
                    has_error = True
            except ValueError:
                messages.error(request, '❌ 贷款利率格式错误，请输入数字')
                has_error = True
        
        # 🟢 修改：在调用 callproc 时传入 account_id
        if not has_error:
            try:
                with connection.cursor() as cursor:
                    # 确保存储过程定义为: add_loan(loan_id, client_id, bank_name, account_id, loan_money, loan_rate, loan_date)
                    cursor.callproc('add_loan', [
                        loan_id, client_id, bank_name, account_id, 
                        loan_money, loan_rate, loan_date
                    ])
                messages.success(request, f'✅ 贷款 {loan_id} 创建成功！')
                return redirect(reverse('banksystem:loan'))
            except Exception as e:
                messages.error(request, f'❌ 创建失败：{str(e)}')
                has_error = True
        
        # 有错误时返回表单，保留用户输入
        suggested_id = generate_loan_id()
        return render(request, 'loan/add_loan.html', {
            'banks': banks,
            'clients': clients,
            'credit_accounts_json': credit_accounts_json,
            'suggested_id': suggested_id,
            'loan_id': loan_id,
            'client_id': client_id,
            'bank_name': bank_name,
            'loan_money': loan_money,
            'loan_rate': loan_rate,
            'loan_date': loan_date
        })
    
    suggested_id = generate_loan_id()
    return render(request, 'loan/add_loan.html', {
        'banks': banks,
        'clients': clients,
        'credit_accounts_json': credit_accounts_json,
        'suggested_id': suggested_id,
        'default_rate': 0.0435  # 默认利率 4.35%
    })

def update_loan(request, loan_id):
    # 获取银行列表
    with connection.cursor() as cursor:
        cursor.execute("SELECT bank_name FROM Bank")
        banks = cursor.fetchall()
    
    with connection.cursor() as cursor:
        cursor.execute("SELECT * FROM loan WHERE loan_id = %s", [loan_id])
        loan = cursor.fetchone()
    
    if not loan:
        return HttpResponseNotFound("Loan not found")
    
    if request.method == 'POST':
        client_id = request.POST.get('client_id')
        bank_name = request.POST.get('bank_name')
        loan_money = request.POST.get('loan_money')
        loan_rate = request.POST.get('loan_rate')
        
        has_error = False
        
        # 验证贷款金额
        try:
            loan_money_float = float(loan_money)
            if loan_money_float <= 0:
                messages.error(request, '❌ 贷款金额必须大于0')
                has_error = True
        except ValueError:
            messages.error(request, '❌ 贷款金额格式错误，请输入数字')
            has_error = True
        
        # 验证客户ID是否存在
        if not has_error:
            with connection.cursor() as cursor:
                cursor.execute("SELECT COUNT(*) FROM client WHERE client_id = %s", [client_id])
                if cursor.fetchone()[0] == 0:
                    messages.error(request, f'❌ 客户ID "{client_id}" 不存在')
                    has_error = True
        
        # 验证银行是否存在
        if not has_error:
            with connection.cursor() as cursor:
                cursor.execute("SELECT COUNT(*) FROM Bank WHERE bank_name = %s", [bank_name])
                if cursor.fetchone()[0] == 0:
                    messages.error(request, f'❌ 银行 "{bank_name}" 不存在')
                    has_error = True
        
        # 验证贷款利率
        try:
            loan_rate_float = float(loan_rate)
        except ValueError:
            messages.error(request, '❌ 贷款利率格式错误')
            has_error = True
        
        if not has_error:
            try:
                with connection.cursor() as cursor:
                    cursor.callproc('update_loan', [loan_id, client_id, bank_name, loan_money, loan_rate])
                messages.success(request, f'✅ 贷款 {loan_id} 修改成功！')
                return redirect(reverse('banksystem:view_loan', kwargs={'loan_id': loan_id}))
            except Exception as e:
                messages.error(request, f'❌ 修改失败：{str(e)}')
                has_error = True
        
        # 有错误时返回表单
        return render(request, 'loan/update_loan.html', {
            'banks': banks,
            'loan_id': loan_id,
            'loan': [loan_id, client_id, bank_name, loan_money, loan_rate, loan[5]],
            'client_id': client_id,
            'bank_name': bank_name,
            'loan_money': loan_money,
            'loan_rate': loan_rate
        })
    
    return render(request, 'loan/update_loan.html', {
        'banks': banks,
        'loan_id': loan_id,
        'loan': loan
    })

# 删除贷款
def delete_loan(request, loan_id):
    try:
        with connection.cursor() as cursor:
            cursor.callproc('delete_loan', [loan_id])
        messages.success(request, f'✅ 贷款 {loan_id} 已成功删除！')
    except Exception as e:
        error_msg = str(e)
        if '尚未还清' in error_msg:
            messages.error(request, f'❌ 贷款 {loan_id} 尚未还清，无法删除！请先还清贷款。')
        else:
            messages.error(request, f'❌ 删除贷款失败：{error_msg}')
    
    return redirect(reverse('banksystem:view_loan', kwargs={'loan_id': loan_id}))

def search_loan(request):
    results = []
    if request.method == 'POST':
        loan_id = request.POST.get('loan_id', None)
        client_id = request.POST.get('client_id', None)
        bank_name = request.POST.get('bank_name', None)
        name = request.POST.get('name', None)

        with connection.cursor() as cursor:
            cursor.callproc('search_loan', [loan_id, client_id, bank_name, name])
            results = cursor.fetchall()
    return render(request, "loan/search_loan.html", {"results": results})

def loan_payment(request, loan_id):
    # 0. 先补算历史欠息（关键！）
    with connection.cursor() as cursor:
        cursor.callproc('ensure_loan_interest_up_to_date', [loan_id])
    
    # 1. 基础信息查询：获取当前贷款详情（加入利息字段）
    with connection.cursor() as cursor:
        cursor.execute("""
            SELECT l.loan_id, l.client_id, l.bank_name, l.loan_money,
                   l.loan_rate, l.loan_date, l.accrued_interest,
                   l.last_interest_date, c.name AS client_name
            FROM loan l
            JOIN client c ON l.client_id = c.client_id
            WHERE l.loan_id = %s
        """, [loan_id])
        row = cursor.fetchone()
    if not row:
        return HttpResponseNotFound("未找到对应的贷款记录")

    loan = {
        'loan_id':            row[0],
        'client_id':          row[1],
        'bank_name':          row[2],
        'loan_money':         float(row[3]),
        'loan_rate':          float(row[4]),
        'loan_date':          row[5],
        'accrued_interest':   float(row[6] or 0),
        'last_interest_date': row[7],
        'client_name':        row[8],
    }

    client_id = loan['client_id']
    bank_name = loan['bank_name']

    # 2. 核心联动查询：获取该客户在这家银行下的所有"可用扣款账户"（储蓄和信用账户）
    # 只有同一个人、同一家银行的账户才可以用来直接还款
    with connection.cursor() as cursor:
        # 查询储蓄账户
        cursor.execute(
            "SELECT account_id, balance, 'saving' AS account_type FROM saving_account WHERE client_id = %s AND bank_name = %s",
            [client_id, bank_name]
        )
        saving_accounts = cursor.fetchall()

        # 查询信用账户
        cursor.execute(
            "SELECT account_id, balance, 'credit' AS account_type FROM credit_account WHERE client_id = %s AND bank_name = %s",
            [client_id, bank_name]
        )
        credit_accounts = cursor.fetchall()
    
    # 合并该客户在该行的所有账户列表，供前端下拉框或单选框选择
    available_accounts = saving_accounts + credit_accounts

    # 3. 动态获取当前贷款剩余需要还款的金额（现在包含利息了）
    with connection.cursor() as cursor:
        cursor.execute("SELECT get_remaining_loan_amount(%s)", [loan_id])
        remaining = float(cursor.fetchone()[0] or 0)
    
    # 4. 处理用户提交的还款表单 (POST)
    if request.method == 'POST':
        pay_money = request.POST.get('pay_money')
        pay_date = request.POST.get('pay_date')
        
        # 【核心修改】从前端获取用户选择用来扣款的账户及类型
        account_info = request.POST.get('account_info')  # 格式设计为 "account_id,account_type"
        
        # 表单安全校验：如果没有选择还款账户
        if not account_info:
            messages.error(request, '❌ 还款失败：请选择用于执行扣款的银行账户！')
            return render(request, 'loan/loan_payment.html', {
                'loan': loan,
                'remaining': remaining,
                'available_accounts': available_accounts
            })
            
        account_id, account_type = account_info.split(',')
        
        try:
            with connection.cursor() as cursor:
                # 【核心修改】传入 5 个参数去调用我们写好的高阶事务存储过程
                # 参数顺序：还款金额, 还款日期, 贷款ID, 扣款账户ID, 账户类型
                cursor.callproc('add_loan_payment', [pay_money, pay_date, loan_id, account_id, account_type])
                
            messages.success(request, f'✅ 还款成功！已成功从账户 {account_id} 扣除 {pay_money} 元。')
            return redirect(reverse('banksystem:view_loan', kwargs={'loan_id': loan_id}))
            
        except Exception as e:
            error_msg = str(e)
            # 完美的异常文案捕获：直接捕捉我们在存储过程中抛出的中文警告
            if '账户余额不足' in error_msg:
                messages.error(request, f'❌ 还款失败：该账户当前余额不足，请先前往进行账户存款！')
            elif '超过剩余贷款' in error_msg:
                messages.error(request, f'❌ 还款失败：还款金额 {pay_money} 元超过了剩余贷款总额 {remaining} 元')
            else:
                messages.error(request, f'❌ 还款失败：{error_msg}')
                
            return render(request, 'loan/loan_payment.html', {
                'loan': loan,
                'remaining': remaining,
                'available_accounts': available_accounts
            })
    
    # 5. 渲染页面 (GET)，将可用账户传递给前端
    return render(request, 'loan/loan_payment.html', {
        'loan': loan,
        'remaining': remaining,
        'available_accounts': available_accounts  # 传给 HTML 渲染下拉列表
    })


def loan_pay_info(request, loan_id):
    with connection.cursor() as cursor:
        cursor.callproc('get_loan_payment', [loan_id])
        loan_pay_info = cursor.fetchall()
    return render(request, 'loan/loan_pay_info.html', {
        'loan_pay_info': loan_pay_info,
        'loan_id': loan_id  
    })