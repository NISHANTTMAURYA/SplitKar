from django.contrib import admin
from django.db.models import Sum, Count
from django.utils.html import format_html
from .models import (
    ExpenseCategory,
    Expense,
    ExpensePayment,
    ExpenseShare,
    Settlement,
    Balance,
    UserTotalBalance
)

@admin.register(ExpenseCategory)
class ExpenseCategoryAdmin(admin.ModelAdmin):
    list_display = ('name', 'colored_icon', 'is_active', 'created_at')
    list_filter = ('is_active', 'created_at')
    search_fields = ('name',)
    ordering = ('name',)
    
    def colored_icon(self, obj):
        return format_html(
            '<span style="color: {};">{}</span>',
            obj.color,
            obj.icon or '⚪'
        )
    colored_icon.short_description = 'Icon'

class ExpensePaymentInline(admin.TabularInline):
    model = ExpensePayment
    extra = 1
    fields = ('payer', 'amount_paid')

class ExpenseShareInline(admin.TabularInline):
    model = ExpenseShare
    extra = 1
    fields = ('user', 'amount_owed', 'amount_paid_back')
    readonly_fields = ('amount_paid_back',)

@admin.register(Expense)
class ExpenseAdmin(admin.ModelAdmin):
    list_display = ('expense_id','description', 'total_amount', 'currency', 'date', 'category', 'group', 'created_by', 'is_deleted')
    list_filter = ('is_deleted', 'currency', 'category', 'group', 'date', 'created_by')
    search_fields = ('description', 'notes', 'created_by__username', 'group__name')
    readonly_fields = ('expense_id', 'created_at', 'updated_at')
    date_hierarchy = 'date'
    inlines = [ExpensePaymentInline, ExpenseShareInline]
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('description', 'total_amount', 'currency', 'date')
        }),
        ('Categorization', {
            'fields': ('category', 'group')
        }),
        ('Split Configuration', {
            'fields': ('split_type',)
        }),
        ('Additional Information', {
            'fields': ('notes', 'created_by', 'is_deleted')
        }),
        ('System Fields', {
            'classes': ('collapse',),
            'fields': ('expense_id', 'created_at', 'updated_at')
        }),
    )
    
    def get_queryset(self, request):
        qs = super().get_queryset(request)
        return qs.select_related('category', 'group', 'created_by')

@admin.register(Settlement)
class SettlementAdmin(admin.ModelAdmin):
    list_display = ('settlement_id', 'payer', 'payee', 'amount', 'currency', 'settlement_method', 'created_at')
    list_filter = ('currency', 'settlement_method', 'created_at', 'group')
    search_fields = ('payer__username', 'payee__username', 'notes')
    readonly_fields = ('settlement_id', 'created_at', 'updated_at')
    date_hierarchy = 'created_at'
    
    fieldsets = (
        ('Settlement Details', {
            'fields': ('payer', 'payee', 'amount', 'currency')
        }),
        ('Method & Context', {
            'fields': ('settlement_method', 'group')
        }),
        ('Additional Information', {
            'fields': ('notes', 'expense_shares')
        }),
        ('System Fields', {
            'classes': ('collapse',),
            'fields': ('settlement_id', 'created_at', 'updated_at')
        }),
    )
    
    def get_queryset(self, request):
        qs = super().get_queryset(request)
        return qs.select_related('payer', 'payee', 'group')

@admin.register(Balance)
class BalanceAdmin(admin.ModelAdmin):
    list_display = ('get_users_display', 'balance_amount', 'currency', 'group', 'updated_at')
    list_filter = ('currency', 'group', 'created_at')
    search_fields = ('user1__username', 'user2__username', 'group__name')
    readonly_fields = ('created_at', 'updated_at')
    
    def get_users_display(self, obj):
        if obj.balance_amount > 0:
            return f"{obj.user1.username} owes {obj.user2.username}"
        elif obj.balance_amount < 0:
            return f"{obj.user1.username} owes {obj.user2.username}"
        return f"{obj.user1.username} ↔ {obj.user2.username} (settled)"
    get_users_display.short_description = 'Users'
    
    def get_queryset(self, request):
        qs = super().get_queryset(request)
        return qs.select_related('user1', 'user2', 'group')

# Optional: Register ExpensePayment and ExpenseShare if you want to manage them directly
@admin.register(ExpensePayment)
class ExpensePaymentAdmin(admin.ModelAdmin):
    list_display = ('expense', 'payer', 'amount_paid', 'created_at')
    list_filter = ('created_at',)
    search_fields = ('expense__description', 'payer__username')
    readonly_fields = ('created_at', 'updated_at')

@admin.register(ExpenseShare)
class ExpenseShareAdmin(admin.ModelAdmin):
    list_display = ('expense', 'user', 'amount_owed', 'amount_paid_back', 'get_remaining')
    list_filter = ('created_at',)
    search_fields = ('expense__description', 'user__username')
    readonly_fields = ('created_at', 'updated_at')
    
    def get_remaining(self, obj):
        return obj.amount_owed - obj.amount_paid_back
    get_remaining.short_description = 'Remaining Amount'

admin.site.register(UserTotalBalance)

