from django.http import HttpResponse
from django.shortcuts import render, redirect
from django.contrib import messages

def signin(request):
    # 如果用户已经登录过了，直接重定向到首页，无需重复登录
    if request.session.get('is_login'):
        return redirect('/index/')

    if request.method == 'POST':
        data = request.POST.dict()

        # 1. 获取表单数据（兼容前端可能叫 'user' 或 'username' 的情况）
        username = data.get("user") or data.get("username")
        password = data.get("password")

        if username and password:
            # 2. 定义合法的多用户字典 (用户名: 密码)
            # 你可以在这里任意添加、修改允许登录的账号和密码
            valid_users = {
                "ruihan": "123456",
                "hjy": "hjy2026",
                "admin": "admin123"
            }

            # 3. 验证用户名是否存在，且密码是否匹配
            if username in valid_users and valid_users[username] == password:
                # 4. 🚀 登录成功：在全局 Session 中标记该用户已登录
                request.session['is_login'] = True
                request.session['username'] = username
                
                # 真正重定向到首页
                return redirect('/index/')
            else:
                messages.error(request, "Invalid username or password")
        else:
            messages.error(request, "Both username and password are required to log in")
            
    return render(request, "signin.html")
        

def index(request):
    # 5. 🛡️ 安全拦截：检查 Session 中是否有登录标记
    if not request.session.get('is_login'):
        # 如果没有登录，用户尝试直接输入 /index/ 访问，直接拦截并踢回登录页
        messages.error(request, "Please log in first.")
        return redirect('/')  # 假设你的根路径 '/' 挂载的是 signin 视图

    # 只有通过验证的用户，才能成功渲染主页
    return render(request, "index.html")


# 💡 顺便赠送一个登出功能（如果你的系统主页有“退出登录”按钮，可以绑定这个路由）
def signout(request):
    # 清除当前用户的 Session 状态
    request.session.flush()
    return redirect('/')