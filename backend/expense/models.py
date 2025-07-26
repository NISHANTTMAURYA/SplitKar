from django.db import models
from django.contrib.auth.models import User
from django.core.exceptions import ValidationError
from django.db.models import Q, Sum, F, Case, When, DecimalField
from django.utils import timezone
from decimal import Decimal
from connections.models import Group, Friendship, Profile
import uuid

class TimeStampedModel(models.Model):
    """Abstract base model with created and modified timestamps"""
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        abstract = True

    def save(self, *args, **kwargs):
        # Ensure timezone awareness for created_at if it's naive
        if hasattr(self, 'created_at') and self.created_at and timezone.is_naive(self.created_at):
            self.created_at = timezone.make_aware(self.created_at, timezone.get_current_timezone())
        super().save(*args, **kwargs)

class ExpenseCategory(TimeStampedModel):
    """Predefined expense categories"""
    name = models.CharField(max_length=50, unique=True)
    icon = models.CharField(max_length=50, blank=True)  # Icon name/code
    color = models.CharField(max_length=7, default='#4CAF50')  # Hex color
    is_active = models.BooleanField(default=True)
    
    class Meta:
        verbose_name_plural = "Expense Categories"
        ordering = ['name']
    
    def __str__(self):
        return self.name

class ExpenseManager(models.Manager):
    def get_expenses_between_users(self, user1, user2, group=None):
        """Get all expenses between two users, optionally filtered by group"""
        base_query = Q(
            # Expenses where user1 paid and user2 owes
            (Q(payments__payer=user1) & Q(shares__user=user2)) |
            # Expenses where user2 paid and user1 owes  
            (Q(payments__payer=user2) & Q(shares__user=user1)) |
            # Expenses where both users are involved in shares
            (Q(shares__user=user1) & Q(shares__user=user2))
        )
        
        if group:
            base_query &= Q(group=group)
            
        return self.filter(base_query, is_deleted=False).distinct().order_by('-date')
    
    def get_user_expenses(self, user, group=None):
        """Get all expenses involving a user"""
        query = Q(payments__payer=user) | Q(shares__user=user) | Q(created_by=user)
        
        if group:
            query &= Q(group=group)
            
        return self.filter(query, is_deleted=False).distinct().order_by('-date')
    
    def get_group_expenses(self, group):
        """Get all expenses for a specific group"""
        return self.filter(group=group, is_deleted=False).order_by('-date')

class Expense(TimeStampedModel):
    """Core expense model supporting multiple payers and flexible contexts"""   
    
    SPLIT_TYPES = [
        ('equal', 'Equal Split'),
        ('exact', 'Exact Amount'), 
        ('percentage', 'Percentage'),
        ('shares', 'Shares'),
    ]
    
    CURRENCY_CHOICES = [
        ('INR', 'Indian Rupee'),
        # Future currencies can be added here
    ]
    
    # Basic expense info
    description = models.CharField(max_length=200, db_index=True)
    total_amount = models.DecimalField(max_digits=12, decimal_places=2)
    currency = models.CharField(max_length=3, choices=CURRENCY_CHOICES, default='INR')
    date = models.DateTimeField(default=timezone.now, db_index=True)
    
    # Category
    category = models.ForeignKey(
        ExpenseCategory, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True
    )
    
    # Context - can be group expense or friend-to-friend
    group = models.ForeignKey(
        'connections.Group', 
        on_delete=models.CASCADE, 
        null=True, 
        blank=True,
        related_name='expenses'
    )
    
    # Split configuration
    split_type = models.CharField(max_length=20, choices=SPLIT_TYPES, default='equal')
    
    # Metadata
    created_by = models.ForeignKey(
        User, 
        on_delete=models.CASCADE, 
        related_name='expenses_created'
    )
    is_deleted = models.BooleanField(default=False, db_index=True)
    notes = models.TextField(blank=True)
    
    # Unique identifier for easy referencing
    expense_id = models.UUIDField(default=uuid.uuid4, unique=True, db_index=True)
    
    objects = ExpenseManager()
    
    class Meta:
        indexes = [
            models.Index(fields=['date', 'is_deleted']),
            models.Index(fields=['group', 'is_deleted']),
            models.Index(fields=['created_by', 'date']),
            models.Index(fields=['expense_id']),
        ]
    
    def __str__(self):
        return f"{self.description} - ₹{self.total_amount}"
    
    def clean(self):
        if self.total_amount <= 0:
            raise ValidationError("Total amount must be positive")
    
    @property
    def total_paid(self):
        """Calculate total amount paid by all payers"""
        return self.payments.aggregate(
            total=Sum('amount_paid')
        )['total'] or Decimal('0')
    
    @property
    def total_owed(self):
        """Calculate total amount owed by all users"""
        return self.shares.aggregate(
            total=Sum('amount_owed')
        )['total'] or Decimal('0')
    
    @property
    def is_balanced(self):
        """Check if total paid equals total owed"""
        return abs(self.total_paid - self.total_owed) < Decimal('0.01')
    
    def get_involved_users(self):
        """Get all users involved in this expense (payers + share holders)"""
        payers = set(self.payments.values_list('payer', flat=True))
        share_holders = set(self.shares.values_list('user', flat=True))
        return User.objects.filter(id__in=payers.union(share_holders))

class ExpensePayment(TimeStampedModel):
    """Track who paid how much for an expense - supports multiple payers"""
    
    expense = models.ForeignKey(
        Expense, 
        on_delete=models.CASCADE, 
        related_name='payments'
    )
    payer = models.ForeignKey(
        User, 
        on_delete=models.CASCADE,
        related_name='expense_payments'
    )
    amount_paid = models.DecimalField(max_digits=12, decimal_places=2)
    
    class Meta:
        unique_together = ('expense', 'payer')
        indexes = [
            models.Index(fields=['expense', 'payer']),
            models.Index(fields=['payer', 'expense']),
        ]
    
    def __str__(self):
        return f"{self.payer.username} paid ₹{self.amount_paid} for {self.expense.description}"
    
    def clean(self):
        if self.amount_paid <= 0:
            raise ValidationError("Payment amount must be positive")

class ExpenseShare(TimeStampedModel):
    """Track who owes how much for each expense"""
    
    expense = models.ForeignKey(
        Expense, 
        on_delete=models.CASCADE, 
        related_name='shares'
    )
    user = models.ForeignKey(
        User, 
        on_delete=models.CASCADE,
        related_name='expense_shares'
    )
    
    # Amount this user owes for this expense
    amount_owed = models.DecimalField(max_digits=12, decimal_places=2)
    
    # For different split types
    percentage = models.DecimalField(
        max_digits=5, 
        decimal_places=2, 
        null=True, 
        blank=True
    )
    shares = models.IntegerField(null=True, blank=True)
    
    # Settlement tracking
    amount_paid_back = models.DecimalField(
        max_digits=12, 
        decimal_places=2, 
        default=Decimal('0')
    )
    
    class Meta:
        unique_together = ('expense', 'user')
        indexes = [
            models.Index(fields=['expense', 'user']),
            models.Index(fields=['user', 'expense']),
        ]
    
    def __str__(self):
        return f"{self.user.username} owes ₹{self.amount_owed} for {self.expense.description}"
    
    @property
    def amount_remaining(self):
        """Amount still owed after settlements"""
        return self.amount_owed - self.amount_paid_back
    
    @property
    def is_settled(self):
        """Check if this share is fully settled"""
        return abs(self.amount_remaining) < Decimal('0.01')
    
    def clean(self):
        if self.amount_owed < 0:
            raise ValidationError("Amount owed cannot be negative")

class SettlementManager(models.Manager):
    def create_settlement(self, payer, payee, amount, expense_shares=None, **kwargs):
        """Create settlement and update related expense shares"""
        settlement = self.create(
            payer=payer,
            payee=payee, 
            amount=amount,
            **kwargs
        )
        
        if expense_shares:
            settlement.expense_shares.set(expense_shares)
            # Update amount_paid_back for each expense share
            for share in expense_shares:
                share.amount_paid_back = F('amount_paid_back') + (amount * share.amount_owed / sum(s.amount_owed for s in expense_shares))
                share.save()
        
        return settlement

class Settlement(TimeStampedModel):
    """Track payments/settlements between users"""
    
    SETTLEMENT_METHODS = [
        ('cash', 'Cash'),
        ('upi', 'UPI'),
        ('bank_transfer', 'Bank Transfer'),
        ('paytm', 'Paytm'),
        ('gpay', 'Google Pay'),
        ('phonepe', 'PhonePe'),
        ('other', 'Other'),
    ]
    
    # Who paid whom
    payer = models.ForeignKey(
        User, 
        on_delete=models.CASCADE, 
        related_name='settlements_made'
    )
    payee = models.ForeignKey(
        User, 
        on_delete=models.CASCADE, 
        related_name='settlements_received'
    )
    
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    currency = models.CharField(max_length=3, default='INR')
    
    # Link to specific expense shares being settled
    expense_shares = models.ManyToManyField(
        ExpenseShare, 
        blank=True,
        related_name='settlements'
    )
    
    # Context
    group = models.ForeignKey(
        'connections.Group', 
        on_delete=models.CASCADE, 
        null=True, 
        blank=True,
        related_name='settlements'
    )
    
    # Settlement details
    settlement_method = models.CharField(
        max_length=20, 
        choices=SETTLEMENT_METHODS, 
        blank=True
    )
    notes = models.TextField(blank=True)
    
    # Unique identifier
    settlement_id = models.UUIDField(default=uuid.uuid4, unique=True, db_index=True)
    
    objects = SettlementManager()
    
    class Meta:
        indexes = [
            models.Index(fields=['payer', 'payee']),
            models.Index(fields=['payee', 'payer']),
            models.Index(fields=['created_at']),
            models.Index(fields=['settlement_id']),
        ]
    
    def __str__(self):
        return f"{self.payer.username} paid ₹{self.amount} to {self.payee.username}"
    
    def clean(self):
        if self.payer == self.payee:
            raise ValidationError("Cannot settle with yourself")
        if self.amount <= 0:
            raise ValidationError("Settlement amount must be positive")

class BalanceManager(models.Manager):
    def get_balance_between_users(self, user1, user2, group=None):
        """Get balance between two users, optionally within a group"""
        # Ensure consistent ordering
        if user1.id > user2.id:
            user1, user2 = user2, user1
            
        balance, created = self.get_or_create(
            user1=user1,
            user2=user2,
            group=group,
            defaults={'balance_amount': Decimal('0')}
        )
        return balance
    
    def update_balance(self, user1, user2, amount_change, group=None):
        """Update balance between two users"""
        balance = self.get_balance_between_users(user1, user2, group)
        
        # Positive amount means user1 owes user2 more
        if user1.id < user2.id:
            balance.balance_amount += amount_change
        else:
            balance.balance_amount -= amount_change
            
        balance.save()
        return balance
    
    def get_user_balances(self, user, group=None):
        """Get all balances for a user"""
        query = Q(user1=user) | Q(user2=user)
        if group:
            query &= Q(group=group)
        return self.filter(query).exclude(balance_amount=0)

class Balance(TimeStampedModel):
    """Aggregate balances between users for quick lookups"""
    
    # Always store with user1.id < user2.id for consistency
    user1 = models.ForeignKey(
        User, 
        on_delete=models.CASCADE, 
        related_name='balances_as_user1'
    )
    user2 = models.ForeignKey(
        User, 
        on_delete=models.CASCADE, 
        related_name='balances_as_user2'
    )
    
    # Positive = user1 owes user2, Negative = user2 owes user1
    balance_amount = models.DecimalField(
        max_digits=12, 
        decimal_places=2, 
        default=Decimal('0')
    )
    currency = models.CharField(max_length=3, default='INR')
    
    # Optional group context (None = overall balance between users)
    group = models.ForeignKey(
        'connections.Group', 
        on_delete=models.CASCADE, 
        null=True, 
        blank=True,
        related_name='balances'
    )
    
    objects = BalanceManager()
    
    class Meta:
        unique_together = ('user1', 'user2', 'group')
        indexes = [
            models.Index(fields=['user1', 'user2']),
            models.Index(fields=['user2', 'user1']),
            models.Index(fields=['user1', 'group']),
            models.Index(fields=['user2', 'group']),
        ]
    
    def __str__(self):
        if self.balance_amount > 0:
            return f"{self.user1.username} owes ₹{self.balance_amount} to {self.user2.username}"
        elif self.balance_amount < 0:
            return f"{self.user1.username} is owed ₹{abs(self.balance_amount)} by {self.user2.username}"
        else:
            return f"{self.user1.username} and {self.user2.username} are settled"
    
    def clean(self):
        if self.user1 == self.user2:
            raise ValidationError("Cannot have balance with yourself")
        if self.user1.id > self.user2.id:
            raise ValidationError("user1 must have smaller ID than user2")
    
    def get_balance_for_user(self, user):
        """Get balance amount from perspective of specified user"""
        if user == self.user1:
            return -self.balance_amount  # Negative if user1 owes user2
        elif user == self.user2:
            return self.balance_amount   # Positive if user1 owes user2
        else:
            raise ValueError("User not part of this balance")

class UserTotalBalanceManager(models.Manager):
    def get_total_balance_between_users(self, user1, user2):
        # Ensure consistent ordering
        if user1.id > user2.id:
            user1, user2 = user2, user1
        obj, created = self.get_or_create(user1=user1, user2=user2, defaults={'total_balance': Decimal('0.00')})
        return obj

    def update_total_balance(self, user1, user2, amount_change):
        obj = self.get_total_balance_between_users(user1, user2)
        if user1.id < user2.id:
            obj.total_balance += amount_change
        else:
            obj.total_balance -= amount_change
        obj.save()
        return obj

class UserTotalBalance(models.Model):
    user1 = models.ForeignKey(User, on_delete=models.CASCADE, related_name='total_balances_as_user1')
    user2 = models.ForeignKey(User, on_delete=models.CASCADE, related_name='total_balances_as_user2')
    total_balance = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal('0.00'))
    last_updated = models.DateTimeField(auto_now=True)

    objects = UserTotalBalanceManager()

    class Meta:
        unique_together = ('user1', 'user2')
        indexes = [
            models.Index(fields=['user1', 'user2']),
            models.Index(fields=['user2', 'user1']),
        ]

    def __str__(self):
        if self.total_balance > 0:
            return f"{self.user1.username} owes ₹{self.total_balance} to {self.user2.username}"
        elif self.total_balance < 0:
            return f"{self.user1.username} is owed ₹{abs(self.total_balance)} by {self.user2.username}"
        else:
            return f"{self.user1.username} and {self.user2.username} are settled"

# Default expense categories
EXPENSE_CATEGORIES = [
    ('Food & Dining', '🍽️', '#FF6B6B'),
    ('Transportation', '🚗', '#4ECDC4'),
    ('Shopping', '🛍️', '#45B7D1'),
    ('Entertainment', '🎬', '#96CEB4'),
    ('Bills & Utilities', '⚡', '#FECA57'),
    ('Travel', '✈️', '#FF9FF3'),
    ('Healthcare', '🏥', '#54A0FF'),
    ('Education', '📚', '#5F27CD'),
    ('Groceries', '🛒', '#00D2D3'),
    ('Other', '📝', '#747D8C'),
]




# testing
"""
# Test in Django shell

from django.contrib.auth.models import User

from expense.models import *

# Create test users

user1 = User.objects.create_user('john', 'john@example.com', 'pass')

user2 = User.objects.create_user('jane', 'jane@example.com', 'pass')

# Create expense - watch the console for signal output

expense = Expense.objects.create(

    description="Test expense",

    total_amount=100,

    created_by=user1

)

# Add payment and shares - signals will automatically update balances

ExpensePayment.objects.create(expense=expense, payer=user1, amount_paid=100)

ExpenseShare.objects.create(expense=expense, user=user1, amount_owed=50)

ExpenseShare.objects.create(expense=expense, user=user2, amount_owed=50)

# Check balance - should show user2 owes user1 ₹50

balance = Balance.objects.get_balance_between_users(user1, user2)

print(f"Balance: {balance}")
"""