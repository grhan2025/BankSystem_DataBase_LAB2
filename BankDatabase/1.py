def update_bank(request, bank_name):
    if request.method == 'POST':
        location = request.POST['location']
        asset = request.POST['asset']
        
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
                # 如果没上传图片，传 None 让存储过程判断
                cursor.execute("CALL UpdateBank(%s, %s, %s, %s)", [bank_name, location, asset, image_url])
            messages.success(request, '银行信息更新成功！')
        except Exception as e:
            messages.error(request, '更新银行信息时出错：' + str(e))
        
        return redirect('banksystem:bankinfo')
    
    with connection.cursor() as cursor:
        cursor.execute("CALL GetBankByName(%s)", [bank_name])
        bank = cursor.fetchone()
    
    return render(request, 'bankinfo/update_bank.html', {'bank': bank})