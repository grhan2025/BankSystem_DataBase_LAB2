from django.urls import path, re_path, include
from BankDatabase import views

app_name = 'banksystem'

urlpatterns = [
    path("client/", views.client_management, name="client"),
    path("account/", views.account_management, name="account"),
    path("bankinfo/", views.bankinfo_management, name="bankinfo"),
    path("loan/", views.loan_management, name="loan"),
    path("add_client/", views.client_add, name="add_client"),
    path("delete_client", views.delete_client, name="delete_client"),
    path("modify_client", views.modify_client, name="modify_client"),
    path("search_client", views.search_client, name="search_client"),
    path("detail_client", views.client_detail, name="detail_client"),
    path('detail_client/<str:client_id>/', views.client_detail, name='detail_client'),
    path('delete_client/<str:client_id>/', views.delete_client_detail, name='delete_client'),
    path('modify_client/<str:client_id>/', views.modify_client_detail, name='modify_client'),

    path("create_credit", views.create_credit, name="create_credit"),
    path("create_saving", views.create_saving, name="create_saving"),
    path("view_account/<str:account_id>/<str:account_type>/", views.view_account, name="view_account"),
    path("delete_account/<str:account_id>/<str:account_type>/", views.delete_account, name="delete_account"),
    path("update_account/<str:account_id>/<str:account_type>/", views.update_account, name="update_account"),
    path("search_account", views.search_account, name="search_account"),

    path("add_bank", views.add_bank, name="add_bank"),
    path("update_bank/<str:bank_name>/", views.update_bank, name="update_bank"),
    path('delete/<str:bank_name>/', views.delete_bank, name='delete_bank'),
    path("search_bank", views.search_bank, name="search_bank"),
    path("bank_info/<str:bank_name>/", views.get_bank_info, name="bank_info"),

    path("add_department/<str:bank_name>/", views.add_department, name="add_department"),
    path("update_department/<str:bank_name>/<str:department_id>/", views.update_department, name="update_department"),
    path('delete_department/<str:bank_name>/<str:department_id>/', views.delete_department, name='delete_department'),
    path("search_department/<str:bank_name>/", views.search_department, name="search_department"),

    path("employee_list/<str:bank_name>/<str:department_id>/", views.get_employees_by_department, name="employee_list"),
    path("add_employee/<str:bank_name>/<str:department_id>/", views.add_employee, name="add_employee"),
    path("update_employee/<str:bank_name>/<str:department_id>/<str:employee_id>/", views.update_employee, name="update_employee"),
    path('delete_employee/<str:bank_name>/<str:department_id>/<str:employee_id>/', views.delete_employee, name='delete_employee'),
    path("search_employee/<str:bank_name>/<str:department_id>/", views.search_employee, name="search_employee"),

    path("view_loan/<str:loan_id>", views.view_loan, name="view_loan"),
    path("add_loan", views.add_loan, name="add_loan"),
    path("update_loan/<str:loan_id>", views.update_loan, name="update_loan"),
    path('delete_loan/<str:loan_id>/', views.delete_loan, name='delete_loan'),
    path("search_loan", views.search_loan, name="search_loan"),
    path("loan_payment/<str:loan_id>", views.loan_payment, name="loan_payment"),
    path("loan_pay_info/<str:loan_id>", views.loan_pay_info, name="loan_pay_info"),
]