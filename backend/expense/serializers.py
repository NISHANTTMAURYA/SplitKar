from rest_framework import serializers
from django.contrib.auth.models import User
from decimal import Decimal
from .models import Expense, ExpensePayment, ExpenseShare, ExpenseCategory
from connections.models import Group, Friendship


class UserSerializer(serializers.ModelSerializer):
    """Simple user serializer for responses"""
    class Meta:
        model = User
        fields = ['id', 'username', 'first_name', 'last_name']


class SplitSerializer(serializers.Serializer):
    user_id = serializers.IntegerField()
    percentage = serializers.DecimalField(max_digits=5, decimal_places=2)


class AddExpenseSerializer(serializers.Serializer):
    """Serializer for adding expenses with equal splitting"""
    
    description = serializers.CharField(max_length=200)
    total_amount = serializers.DecimalField(max_digits=12, decimal_places=2)
    payer_id = serializers.IntegerField()
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
        """Validate that total amount is positive"""
        if value <= 0:
            raise serializers.ValidationError("Total amount must be positive")
        return value
    
    def validate_group_id(self, value):
        """Validate that group exists and is active"""
        try:
            group = Group.objects.get(id=value, is_active=True)
        except Group.DoesNotExist:
            raise serializers.ValidationError("Group not found or inactive")
        return value
    
    def validate_category_id(self, value):
        if value is not None:
            try:
                ExpenseCategory.objects.get(id=value)
            except ExpenseCategory.DoesNotExist:
                raise serializers.ValidationError("Invalid category ID")
        return value
    
    def validate_payer_id(self, value):
        """Validate that payer exists"""
        try:
            User.objects.get(id=value)
        except User.DoesNotExist:
            raise serializers.ValidationError("Payer not found")
        return value
    
    def validate_user_ids(self, value):
        """Validate that all users exist"""
        if not value:
            raise serializers.ValidationError("user_ids cannot be empty")
        
        # Check if all users exist
        existing_users = User.objects.filter(id__in=value)
        if len(existing_users) != len(value):
            existing_ids = set(existing_users.values_list('id', flat=True))
            missing_ids = set(value) - existing_ids
            raise serializers.ValidationError(f"Users with IDs {missing_ids} not found")
        
        return value
    
    def validate(self, attrs):
        """Additional validation"""
        # Ensure payer is included in user_ids
        if attrs['payer_id'] not in attrs['user_ids']:
            raise serializers.ValidationError("Payer must be included in user_ids")
        
        # Validate that all users are members of the specified group
        group_id = attrs['group_id']
        # Force all user_ids to int to avoid type mismatch
        user_ids = [int(uid) for uid in attrs['user_ids']]
        
        try:
            group = Group.objects.get(id=group_id, is_active=True)

            # Get all group members
            all_group_members = group.members.all()
            all_group_member_ids = list(all_group_members.values_list('id', flat=True))
            print(f"All group member IDs: {all_group_member_ids}")
            print(f"All group member count: {all_group_members.count()}")
            
            # Check if all users are members of this group using filter
            group_members = group.members.filter(id__in=user_ids)
            group_member_ids = list(group_members.values_list('id', flat=True))
            print(f"Filtered group member IDs: {group_member_ids}")
            print(f"Filtered group member count: {group_members.count()}")
            
            # Check if all user_ids are in the group
            if len(group_member_ids) != len(user_ids):
                non_member_ids = set(user_ids) - set(group_member_ids)
                print(f"Non-member IDs: {non_member_ids}")
                print(f"=== END DEBUG ===")
                raise serializers.ValidationError(
                    f"Users with IDs {non_member_ids} are not members of the specified group"
                )
            
            print(f"=== END DEBUG ===")
        except Group.DoesNotExist:
            raise serializers.ValidationError("Group not found or inactive")
        
        attrs['user_ids'] = user_ids  # Overwrite with int-cast user_ids

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
        """Create the expense with equal splitting"""
        from django.db import transaction
        
        user_ids = validated_data.pop('user_ids')
        payer_id = validated_data.pop('payer_id')
        group_id = validated_data.pop('group_id')
        split_type = validated_data.pop('split_type', 'equal')
        splits = validated_data.pop('splits', None)
        category_id = validated_data.pop('category_id', None)
        
        # Get all users and group
        users = User.objects.filter(id__in=user_ids)
        payer = User.objects.get(id=payer_id)
        group = Group.objects.get(id=group_id)
        category = None
        if category_id is not None:
            category = ExpenseCategory.objects.get(id=category_id)
        
        # Calculate equal split
        total_amount = validated_data['total_amount']
        
        with transaction.atomic():
            # Create expense with group
            expense = Expense.objects.create(
                **validated_data,
                group=group,
                category=category,
                split_type=split_type,
                created_by=self.context['request'].user
            )
            
            # Create payment record
            ExpensePayment.objects.create(
                expense=expense,
                payer=payer,
                amount_paid=total_amount
            )
            
            # Create equal shares for all users
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
        from django.db import transaction
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
            return expense 