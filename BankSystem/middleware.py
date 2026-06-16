from django.shortcuts import redirect
from django.contrib import messages

class LoginRequiredMiddleware:
    """全局登录检查中间件"""
    
    def __init__(self, get_response):
        self.get_response = get_response
        # 白名单：这些路径不需要登录即可访问
        self.whitelist = ['/', '/signin/', '/signout/']
    
    def __call__(self, request):
        # 检查当前路径是否在白名单中
        if request.path not in self.whitelist:
            # 如果不在白名单，检查是否已登录
            if not request.session.get('is_login'):
                messages.error(request, "Please log in first.")
                return redirect('/')
        
        response = self.get_response(request)
        return response