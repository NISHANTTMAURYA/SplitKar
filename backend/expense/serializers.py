from rest_framework import serializers
from django.contrib.auth.models import User
from decimal import Decimal
from django.utils import timezone
from .models import Expense, ExpensePayment, ExpenseShare, ExpenseCategory, UserTotalBalance, Balance
from connections.models import Group, Friendship
from django.db.models import Sum
from django.db import transaction
from .signals import recalculate_user_balances


class UserSerializer(serializers.ModelSerializer):
    """Simple user serializer for responses"""
    class Meta:
        model = User
        fields = ['id', 'username', 'first_name', 'last_name']


class SplitSerializer(serializers.Serializer):
    user_id = serializers.IntegerField()
    percentage = serializers.DecimalField(max_digits=5, decimal_places=2)


class AddExpensePaymentSerializer(serializers.Serializer):
    payer_id = serializers.IntegerField()
    amount_paid = serializers.DecimalField(max_digits=12, decimal_places=2)


class AddExpenseSerializer(serializers.Serializer):
    description = serializers.CharField(max_length=200)
    total_amount = serializers.DecimalField(
        max_digits=12, 
        decimal_places=2,
        min_value=Decimal('0.01'),
        error_messages={
            'min_value': 'Total amount must be greater than 0',
            'invalid': 'Please enter a valid amount',
            'required': 'Total amount is required',
            'null': 'Total amount cannot be null'
        }
    )
    payments = AddExpensePaymentSerializer(many=True)
    user_ids = serializers.ListField(
        child=serializers.IntegerField(),
        min_length=1
    )
    group_id = serializers.IntegerField()
    category_id = serializers.IntegerField(required=False, allow_null=True)
    currency = serializers.CharField(max_length=3, default='INR')
    notes = serializers.CharField(max_length=500, required=False, allow_blank=True)
    split_type = serializers.ChoiceField(choices=[('equal', 'Equal'), ('percentage', 'Percentage')], default='equal')
    splits = SplitSerializer(many=True, required=False)

    def validate_total_amount(self, value):
        if value <= 0:
            raise serializers.ValidationError("Total amount must be positive")
        return value

    def validate_payments(self, value):
        if not value or len(value) == 0:
            raise serializers.ValidationError("At least one payer is required.")
        payer_ids = [p['payer_id'] for p in value]
        if len(set(payer_ids)) != len(payer_ids):
            raise serializers.ValidationError("Duplicate payer_id in payments.")
        return value

    def validate(self, attrs):
        user_ids = [int(uid) for uid in attrs['user_ids']]
        group_id = attrs['group_id']
        payments = attrs['payments']
        total_amount = attrs['total_amount']
        # Validate all payers exist and are in user_ids
        payer_ids = [p['payer_id'] for p in payments]
        existing_users = User.objects.filter(id__in=payer_ids)
        if len(existing_users) != len(payer_ids):
            existing_ids = set(existing_users.values_list('id', flat=True))
            missing_ids = set(payer_ids) - existing_ids
            raise serializers.ValidationError(f"Payers with IDs {missing_ids} not found")
        for pid in payer_ids:
            if pid not in user_ids:
                raise serializers.ValidationError(f"Payer {pid} must be included in user_ids")
        # Validate sum of payments
        sum_paid = sum(Decimal(p['amount_paid']) for p in payments)
        if abs(sum_paid - total_amount) > Decimal('0.01'):
            raise serializers.ValidationError("Sum of all payments must equal total_amount")
        # Validate all users exist
        group = Group.objects.get(id=group_id, is_active=True)
        group_members = group.members.filter(id__in=user_ids)
        if group_members.count() != len(user_ids):
            group_member_ids = set(group_members.values_list('id', flat=True))
            non_member_ids = set(user_ids) - group_member_ids
            raise serializers.ValidationError(f"Users with IDs {non_member_ids} are not members of the specified group")
        attrs['user_ids'] = user_ids
        # Percentage split validation
        if attrs.get('split_type', 'equal') == 'percentage':
            splits = attrs.get('splits')
            if not splits or len(splits) == 0:
                raise serializers.ValidationError("Splits are required for percentage split.")
            split_user_ids = [int(s['user_id']) for s in splits]
            if set(split_user_ids) != set(user_ids):
                raise serializers.ValidationError("Splits must be provided for all users in user_ids.")
            total_percentage = sum(Decimal(s['percentage']) for s in splits)
            if abs(total_percentage - Decimal('100')) > Decimal('0.01'):
                raise serializers.ValidationError("Total percentage must equal 100%.")
        return attrs

    def create(self, validated_data):
        user_ids = validated_data.pop('user_ids')
        payments = validated_data.pop('payments')
        group_id = validated_data.pop('group_id')
        split_type = validated_data.pop('split_type', 'equal')
        splits = validated_data.pop('splits', None)
        category_id = validated_data.pop('category_id', None)
        users = User.objects.filter(id__in=user_ids)
        group = Group.objects.get(id=group_id)
        category = None
        if category_id is not None:
            category = ExpenseCategory.objects.get(id=category_id)
        total_amount = validated_data['total_amount']
        with transaction.atomic():
            expense = Expense.objects.create(
                **validated_data,
                group=group,
                category=category,
                split_type=split_type,
                created_by=self.context['request'].user
            )
            for payment in payments:
                payer = User.objects.get(id=payment['payer_id'])
                ExpensePayment.objects.create(
                    expense=expense,
                    payer=payer,
                    amount_paid=payment['amount_paid']
                )
            if split_type == 'equal':
                split_amount = total_amount / len(users)
                for user in users:
                    ExpenseShare.objects.create(
                        expense=expense,
                        user=user,
                        amount_owed=split_amount
                    )
            elif split_type == 'percentage':
                for s in splits:
                    share_user = User.objects.get(id=s['user_id'])
                    percentage = Decimal(s['percentage'])
                    owed = (total_amount * percentage / 100).quantize(Decimal('0.01'))
                    ExpenseShare.objects.create(
                        expense=expense,
                        user=share_user,
                        percentage=percentage,
                        amount_owed=owed
                    )
            involved_users = set()
            involved_users.update([s.user for s in expense.shares.all()])
            involved_users.update([p.payer for p in expense.payments.all()])
            for user in involved_users:
                recalculate_user_balances(user)
            return expense

    @staticmethod
    def get_category_choices():
        return ExpenseCategory.objects.all().values('id', 'name', 'icon', 'color')


class ExpenseResponseSerializer(serializers.Serializer):
    """Serializer for expense response"""
    
    message = serializers.CharField()
    expense_id = serializers.UUIDField()
    description = serializers.CharField()
    total_amount = serializers.CharField()
    split_amount = serializers.CharField()
    num_users = serializers.IntegerField()
    users = UserSerializer(many=True)


class AddFriendExpenseSerializer(serializers.Serializer):
    description = serializers.CharField(max_length=200)
    total_amount = serializers.DecimalField(max_digits=12, decimal_places=2)
    payer_id = serializers.IntegerField()
    friend_ids = serializers.ListField(
        child=serializers.IntegerField(),
        min_length=1
    )
    category_id = serializers.IntegerField(required=False, allow_null=True)
    currency = serializers.CharField(max_length=3, default='INR')
    notes = serializers.CharField(max_length=500, required=False, allow_blank=True)
    split_type = serializers.ChoiceField(choices=[('equal', 'Equal'), ('percentage', 'Percentage')], default='equal')
    splits = SplitSerializer(many=True, required=False)

    def validate_total_amount(self, value):
        if value <= 0:
            raise serializers.ValidationError("Total amount must be positive")
        return value

    def validate_payer_id(self, value):
        try:
            User.objects.get(id=value)
        except User.DoesNotExist:
            raise serializers.ValidationError("Payer not found")
        return value

    def validate_friend_ids(self, value):
        if not value:
            raise serializers.ValidationError("friend_ids cannot be empty")
        existing_users = User.objects.filter(id__in=value)
        if len(existing_users) != len(value):
            existing_ids = set(existing_users.values_list('id', flat=True))
            missing_ids = set(value) - existing_ids
            raise serializers.ValidationError(f"Users with IDs {missing_ids} not found")
        return value

    def validate(self, attrs):
        payer_id = attrs['payer_id']
        friend_ids = [int(uid) for uid in attrs['friend_ids']]
        if payer_id not in friend_ids:
            raise serializers.ValidationError("Payer must be included in friend_ids")
        # Validate all friend_ids are friends of payer
        payer = User.objects.get(id=payer_id)
        friends = set(u.id for u in Friendship.objects.friends_of(payer))
        for uid in friend_ids:
            if uid != payer_id and uid not in friends:
                raise serializers.ValidationError(f"User {uid} is not a friend of payer {payer_id}")
        attrs['friend_ids'] = friend_ids
        if attrs.get('split_type', 'equal') == 'percentage':
            splits = attrs.get('splits')
            if not splits or len(splits) == 0:
                raise serializers.ValidationError("Splits are required for percentage split.")
            split_user_ids = [int(s['user_id']) for s in splits]
            if set(split_user_ids) != set(friend_ids):
                raise serializers.ValidationError("Splits must be provided for all users in friend_ids.")
            total_percentage = sum(Decimal(s['percentage']) for s in splits)
            if abs(total_percentage - Decimal('100')) > Decimal('0.01'):
                raise serializers.ValidationError("Total percentage must equal 100%.")
        return attrs

    def create(self, validated_data):
        friend_ids = validated_data.pop('friend_ids')
        payer_id = validated_data.pop('payer_id')
        split_type = validated_data.pop('split_type', 'equal')
        splits = validated_data.pop('splits', None)
        category_id = validated_data.pop('category_id', None)
        users = User.objects.filter(id__in=friend_ids)
        payer = User.objects.get(id=payer_id)
        category = None
        if category_id is not None:
            category = ExpenseCategory.objects.get(id=category_id)
        total_amount = validated_data['total_amount']
        with transaction.atomic():
            expense = Expense.objects.create(
                **validated_data,
                group=None,  # No group for friend expenses
                category=category,
                split_type=split_type,
                created_by=self.context['request'].user
            )
            ExpensePayment.objects.create(
                expense=expense,
                payer=payer,
                amount_paid=total_amount
            )
            if split_type == 'equal':
                split_amount = total_amount / len(users)
                for user in users:
                    ExpenseShare.objects.create(
                        expense=expense,
                        user=user,
                        amount_owed=split_amount
                    )
            elif split_type == 'percentage':
                for s in splits:
                    share_user = User.objects.get(id=s['user_id'])
                    percentage = Decimal(s['percentage'])
                    owed = (total_amount * percentage / 100).quantize(Decimal('0.01'))
                    ExpenseShare.objects.create(
                        expense=expense,
                        user=share_user,
                        percentage=percentage,
                        amount_owed=owed
                    )
            # Recalculate balances for all involved users
            involved_users = set()
            involved_users.update([s.user for s in expense.shares.all()])
            involved_users.update([p.payer for p in expense.payments.all()])
            for user in involved_users:
                recalculate_user_balances(user)
            return expense 


class UserTotalBalanceSerializer(serializers.ModelSerializer):
    other_user_id = serializers.SerializerMethodField()
    other_user_username = serializers.SerializerMethodField()

    class Meta:
        model = UserTotalBalance
        fields = ['id', 'other_user_id', 'other_user_username', 'total_balance', 'last_updated']

    def get_other_user_id(self, obj):
        user = self.context.get('user')
        if obj.user1 == user:
            return obj.user2.id
        else:
            return obj.user1.id

    def get_other_user_username(self, obj):
        user = self.context.get('user')
        if obj.user1 == user:
            return obj.user2.username
        else:
            return obj.user1.username 


class BalanceSerializer(serializers.ModelSerializer):
    user1 = UserSerializer()
    user2 = UserSerializer()
    
    class Meta:
        model = Balance
        fields = ['id', 'user1', 'user2', 'balance_amount', 'currency', 'group']


class ExpenseListSerializer(serializers.ModelSerializer):
    payer_id = serializers.SerializerMethodField()
    payer_name = serializers.SerializerMethodField()
    payer_profile_pic = serializers.SerializerMethodField()
    owed_breakdown = serializers.SerializerMethodField()
    you_owe = serializers.SerializerMethodField()
    group_name = serializers.SerializerMethodField()
    category = serializers.SerializerMethodField()
    is_user_expense = serializers.SerializerMethodField()
    date = serializers.SerializerMethodField()
    created_by = serializers.SerializerMethodField()
    group_admin_id = serializers.SerializerMethodField()

    class Meta:
        model = Expense
        fields = ['expense_id', 'description', 'total_amount', 'currency', 'date', 
                 'group_name', 'payer_id', 'payer_name', 'payer_profile_pic',
                 'owed_breakdown', 'you_owe', 'category', 'is_user_expense', 'created_by', 'group_admin_id']
        read_only_fields = fields

    def get_group_name(self, obj):
        return obj.group.name if obj.group else None

    def get_payer_id(self, obj):
        payment = obj.payments.first()
        return payment.payer.id if payment else None

    def get_payer_name(self, obj):
        payment = obj.payments.first()
        if not payment:
            return None
        payer = payment.payer
        return payer.get_full_name() or payer.username

    def get_payer_profile_pic(self, obj):
        payment = obj.payments.first()
        if not payment:
            return ''
        try:
            return payment.payer.profile.profile_picture_url or ''
        except:
            return ''

    def get_owed_breakdown(self, obj):
        payments = obj.payments.all()
        if not payments:
            return []
        payer = payments.first().payer
        breakdown = []
        for share in obj.shares.exclude(user=payer):
            user = share.user
            try:
                profile_pic = user.profile.profile_picture_url or ''
            except:
                profile_pic = ''
            breakdown.append({
                'user_id': user.id,
                'name': user.get_full_name() or user.username,
                'amount': str(share.amount_owed),
                'profilePic': profile_pic
            })
        return breakdown

    def get_you_owe(self, obj):
        user = self.context.get('user')
        return obj.shares.filter(user=user).aggregate(total=Sum('amount_owed'))['total'] or 0 

    def get_category(self, obj):
        if obj.category:
            return {
                'id': obj.category.id,
                'name': obj.category.name,
                'icon': obj.category.icon,
                'color': obj.category.color,
            }
        return None 

    def get_is_user_expense(self, obj):
        user = self.context.get('user')
        if not user:
            return False
        payment = obj.payments.first()
        return payment.payer.id == user.id if payment else False 

    def get_date(self, obj):
        """Return date in ISO format with proper timezone handling"""
        if obj.date:
            # Convert to timezone-aware datetime if it's naive
            if timezone.is_naive(obj.date):
                obj.date = timezone.make_aware(obj.date, timezone.get_current_timezone())
            return obj.date.isoformat()
        return None 

    def get_created_by(self, obj):
        return obj.created_by.id if obj.created_by else None

    def get_group_admin_id(self, obj):
        if obj.group and obj.group.created_by:
            return obj.group.created_by.id
        return None


class EditExpenseSerializer(serializers.Serializer):
    expense_id = serializers.UUIDField(required=True)
    description = serializers.CharField(max_length=200, required=False)
    total_amount = serializers.DecimalField(
        max_digits=12, 
        decimal_places=2,
        min_value=Decimal('0.01'),
        required=False
    )
    category_id = serializers.IntegerField(required=False, allow_null=True)
    payer_id = serializers.IntegerField(required=False)
    user_ids = serializers.ListField(
        child=serializers.IntegerField(),
        min_length=1,
        required=False
    )
    splits = SplitSerializer(many=True, required=False)
    split_type = serializers.ChoiceField(choices=[('equal', 'Equal'), ('percentage', 'Percentage')], required=False)
    currency = serializers.CharField(max_length=3, required=False)
    notes = serializers.CharField(max_length=500, required=False, allow_blank=True)

    def validate(self, attrs):
        try:
            expense = Expense.objects.get(
                expense_id=attrs['expense_id'],
                is_deleted=False
            )
            attrs['expense'] = expense
        except Expense.DoesNotExist:
            raise serializers.ValidationError("Expense not found")

        # Ensure at least one field is provided for editing
        editable_fields = [
            'description', 'total_amount', 'category_id', 'payer_id', 'user_ids', 'splits', 'split_type', 'currency', 'notes'
        ]
        if not any(f in attrs for f in editable_fields):
            raise serializers.ValidationError("At least one field must be provided to edit the expense.")

        # Validate category
        category_id = attrs.get('category_id')
        if category_id is not None:
            if category_id:
                try:
                    ExpenseCategory.objects.get(id=category_id)
                except ExpenseCategory.DoesNotExist:
                    raise serializers.ValidationError("Invalid category ID")

        # Validate payer
        payer_id = attrs.get('payer_id')
        if payer_id is not None:
            try:
                User.objects.get(id=payer_id)
            except User.DoesNotExist:
                raise serializers.ValidationError("Payer not found")

        # Validate user_ids
        user_ids = attrs.get('user_ids')
        if user_ids is not None:
            if not user_ids:
                raise serializers.ValidationError("user_ids cannot be empty")
            existing_users = User.objects.filter(id__in=user_ids)
            if len(existing_users) != len(user_ids):
                existing_ids = set(existing_users.values_list('id', flat=True))
                missing_ids = set(user_ids) - existing_ids
                raise serializers.ValidationError(f"Users with IDs {missing_ids} not found")
            if payer_id is not None and payer_id not in user_ids:
                raise serializers.ValidationError("Payer must be included in user_ids")

        # Validate splits for percentage
        split_type = attrs.get('split_type', getattr(expense, 'split_type', 'equal'))
        if split_type == 'percentage':
            splits = attrs.get('splits')
            ids = user_ids if user_ids is not None else list(expense.shares.values_list('user_id', flat=True))
            if not splits or len(splits) == 0:
                raise serializers.ValidationError("Splits are required for percentage split.")
            split_user_ids = [int(s['user_id']) for s in splits]
            if set(split_user_ids) != set(ids):
                raise serializers.ValidationError("Splits must be provided for all users in user_ids.")
            total_percentage = sum(Decimal(s['percentage']) for s in splits)
            if abs(total_percentage - Decimal('100')) > Decimal('0.01'):
                raise serializers.ValidationError("Total percentage must equal 100%.")

        return attrs

    def update(self, instance):
        from django.db import transaction
        from decimal import Decimal
        from .models import ExpenseShare, ExpensePayment, ExpenseCategory
        from django.contrib.auth.models import User

        with transaction.atomic():
            # Load all shares & payment info BEFORE any deletion or updates
            shares = list(instance.shares.all())
            payment = instance.payments.first()

            # Update core fields only if present
            if 'description' in self.validated_data:
                instance.description = self.validated_data['description']
            if 'total_amount' in self.validated_data:
                instance.total_amount = self.validated_data['total_amount']
            if 'category_id' in self.validated_data:
                category_id = self.validated_data['category_id']
                instance.category = ExpenseCategory.objects.get(id=category_id) if category_id else None
            if 'split_type' in self.validated_data:
                instance.split_type = self.validated_data['split_type']
            if 'currency' in self.validated_data:
                instance.currency = self.validated_data['currency']
            if 'notes' in self.validated_data:
                instance.notes = self.validated_data['notes']
            instance.save()

            # Update payer if changed
            payer_changed = False
            previous_payer_id = payment.payer.id if payment else None
            if 'payer_id' in self.validated_data and payment:
                new_payer_id = self.validated_data['payer_id']
                if payment.payer.id != new_payer_id:
                    # Delete previous payment
                    payment.delete()
                    # Create new payment for new payer
                    new_payer = User.objects.get(id=new_payer_id)
                    ExpensePayment.objects.create(
                        expense=instance,
                        payer=new_payer,
                        amount_paid=instance.total_amount
                    )
                    payer_changed = True
                    payment = instance.payments.first()  # Update reference
            # Always update payment amount if total_amount changed
            amount_changed = False
            if 'total_amount' in self.validated_data:
                payment.amount_paid = instance.total_amount
                amount_changed = True
            if payer_changed or amount_changed:
                payment.save()

            # If payer changed, update amount_paid_back for all shares
            if payer_changed:
                current_payer_id = payment.payer.id if payment else None
                for share in instance.shares.all():
                    if share.user_id == current_payer_id:
                        share.amount_paid_back = share.amount_owed
                    else:
                        share.amount_paid_back = 0
                    share.save(update_fields=["amount_paid_back"])

            # Update user_ids if changed
            if 'user_ids' in self.validated_data:
                new_user_ids = set(self.validated_data['user_ids'])
                old_user_ids = set(share.user.id for share in shares)
                if new_user_ids != old_user_ids:
                    # Delete old shares and create new ones
                    instance.shares.all().delete()
                    if instance.split_type == 'equal':
                        per_user_amount = instance.total_amount / len(new_user_ids)
                        for uid in new_user_ids:
                            ExpenseShare.objects.create(
                                expense=instance,
                                user=User.objects.get(id=uid),
                                amount_owed=per_user_amount
                            )
                    elif instance.split_type == 'percentage':
                        splits = self.validated_data.get('splits', [])
                        for s in splits:
                            share_user = User.objects.get(id=s['user_id'])
                            percentage = Decimal(s['percentage'])
                            owed = (instance.total_amount * percentage / 100).quantize(Decimal('0.01'))
                            ExpenseShare.objects.create(
                                expense=instance,
                                user=share_user,
                                percentage=percentage,
                                amount_owed=owed
                            )
                else:
                    # Only update owed amounts for existing shares
                    if instance.split_type == 'equal':
                        per_user_amount = instance.total_amount / len(shares)
                        for share in shares:
                            share.amount_owed = per_user_amount
                            share.save()
                    elif instance.split_type == 'percentage':
                        for share in shares:
                            if share.percentage is None:
                                raise ValueError(f"Percentage missing for user {share.user.username}")
                            share.amount_owed = (instance.total_amount * share.percentage / 100).quantize(Decimal('0.01'))
                            share.save()
            else:
                # No user_ids change, just update owed amounts if total_amount changed
                if 'total_amount' in self.validated_data:
                    if instance.split_type == 'equal':
                        per_user_amount = instance.total_amount / len(shares)
                        for share in shares:
                            share.amount_owed = per_user_amount
                            share.save()
                    elif instance.split_type == 'percentage':
                        for share in shares:
                            if share.percentage is None:
                                raise ValueError(f"Percentage missing for user {share.user.username}")
                            share.amount_owed = (instance.total_amount * share.percentage / 100).quantize(Decimal('0.01'))
                            share.save()

            # Recalculate balances for all involved users
            involved_users = set()
            involved_users.update([s.user for s in instance.shares.all()])
            involved_users.update([p.payer for p in instance.payments.all()])
            for user in involved_users:
                recalculate_user_balances(user)

        return instance 