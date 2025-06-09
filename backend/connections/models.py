from django.db import models 
from django.contrib.auth.models import User 
from django.db.models import Q, Case, When, F 
from django.core.exceptions import ValidationError 
from django.db.models.signals import post_save 
from django.dispatch import receiver 
import uuid 
import string 
import random 
 
# Create your models here.

class TimeStampedModel(models.Model): 
    """Abstract base class with created_at and updated_at fields""" 
    created_at = models.DateTimeField(auto_now_add=True) 
    updated_at = models.DateTimeField(auto_now=True) 
     
    class Meta: 
        abstract = True 
 
class Profile(TimeStampedModel): 
    user = models.OneToOneField(User, on_delete=models.CASCADE) 
    profile_code = models.CharField(max_length=20, unique=True, db_index=True) 
    is_active = models.BooleanField(default=True) 
    profile_picture_url = models.URLField(max_length=500, blank=True, null=True)
    
    class Meta: 
        indexes = [ 
            models.Index(fields=['profile_code']), 
            models.Index(fields=['is_active']), 
        ] 
     
    def __str__(self): 
        return f"{self.user.username} Profile" 
     
    def generate_unique_code(self):
        """Generate a unique profile code using username and random characters"""
        # Get first 6 chars of username, or full username if shorter
        # Remove any special characters and spaces from username
        clean_username = ''.join(c for c in self.user.username if c.isalnum())
        username_prefix = clean_username[:7].upper()
        
        # Generate 3 random chars to ensure uniqueness
        random_suffix = ''.join(random.choices(string.ascii_uppercase + string.digits, k=4))
        code = f"{username_prefix}@{random_suffix}"
        
        # If code already exists, try again with different random suffix
        while Profile.objects.filter(profile_code=code).exists():
            random_suffix = ''.join(random.choices(string.ascii_uppercase + string.digits, k=4))
            code = f"{username_prefix}@{random_suffix}"
        
        return code

    def save(self, *args, **kwargs): 
        if not self.profile_code: 
            self.profile_code = self.generate_unique_code() 
        super().save(*args, **kwargs) 

    def get_high_res_photo_url(self, photo_url):
        """Convert profile picture URL to highest resolution version"""
        if not photo_url:
            return ''
        # Remove any existing size parameters and get base URL
        base_url = photo_url.split('=')[0]
        # Add size parameter for highest resolution (s999)
        return f'{base_url}=s999'
    
    def update_profile_picture(self, photo_url):
        """Update profile picture with high resolution URL only if different"""
        if not photo_url:
            return
            
        high_res_url = self.get_high_res_photo_url(photo_url)
        # Only update if the URL is different
        if self.profile_picture_url != high_res_url:
            self.profile_picture_url = high_res_url
            self.save()

class FriendRequestManager(models.Manager): 
    def send_request(self, from_user, to_user): 
        """Send friend request, handling duplicates gracefully""" 
        if self.filter(from_user=from_user, to_user=to_user).exists(): 
            raise ValidationError("Friend request already sent") 
        if self.filter(from_user=to_user, to_user=from_user).exists(): 
            raise ValidationError("Friend request already received from this user") 
        return self.create(from_user=from_user, to_user=to_user) 
 
class FriendRequest(TimeStampedModel): 
    STATUS_CHOICES = [ 
        ('pending', 'Pending'), 
        ('accepted', 'Accepted'),  
        ('declined', 'Declined') 
    ] 
     
    from_user = models.ForeignKey( 
        User,  
        related_name='sent_friend_requests',  
        on_delete=models.CASCADE 
    ) 
    to_user = models.ForeignKey( 
        User,  
        related_name='received_friend_requests',  
        on_delete=models.CASCADE 
    ) 
    status = models.CharField( 
        max_length=10, 
        choices=STATUS_CHOICES, 
        default='pending', 
        db_index=True 
    ) 
     
    objects = FriendRequestManager() 
     
    class Meta: 
        unique_together = ('from_user', 'to_user') 
        indexes = [ 
            models.Index(fields=['to_user', 'status']), 
            models.Index(fields=['from_user', 'status']), 
            models.Index(fields=['created_at']), 
        ] 
     
    def clean(self): 
        if self.from_user == self.to_user: 
            raise ValidationError("Cannot send friend request to yourself.") 
     
    def save(self, *args, **kwargs): 
        self.clean() 
        super().save(*args, **kwargs) 
     
    def accept(self): 
        """Accept friend request and create friendship""" 
        if self.status == 'pending': 
            self.status = 'accepted' 
            self.save() 
             
            # Create friendship with proper ordering 
            user1 = self.from_user if self.from_user.id < self.to_user.id else self.to_user 
            user2 = self.to_user if self.from_user.id < self.to_user.id else self.from_user 
             
            Friendship.objects.get_or_create(user1=user1, user2=user2) 
     
    def decline(self): 
        """Decline friend request""" 
        if self.status == 'pending': 
            self.status = 'declined' 
            self.save() 
     
    def __str__(self): 
        return f"{self.from_user.username} → {self.to_user.username} ({self.status})" 
 
 
# Signal to auto-create Profile when User is created 
@receiver(post_save, sender=User) 
def create_user_profile(sender, instance, created, **kwargs): 
    if created: 
        Profile.objects.create(user=instance) 
 
class FriendshipManager(models.Manager): 
    def are_friends(self, user_a, user_b): 
        """Check if two users are friends""" 
        user1, user2 = (user_a, user_b) if user_a.id < user_b.id else (user_b, user_a) 
        return self.filter(user1=user1, user2=user2).exists() 
     
    def friends_of(self, user): 
        """Get all friends of a user - optimized query with latest first""" 
        friendships = self.filter( 
            Q(user1=user) | Q(user2=user) 
        ).select_related('user1', 'user2', 'user1__profile', 'user2__profile').order_by('-created_at')
         
        return [ 
            fs.user2 if fs.user1 == user else fs.user1  
            for fs in friendships 
        ] 
     
    def mutual_friends(self, user_a, user_b): 
        """Find mutual friends between two users""" 
        friends_a = set(self.friends_of(user_a)) 
        friends_b = set(self.friends_of(user_b)) 
        return list(friends_a.intersection(friends_b)) 
     
    def delete_friendship(self, user_a, user_b): 
        """Remove friendship between two users""" 
        user1, user2 = (user_a, user_b) if user_a.id < user_b.id else (user_b, user_a) 
        return self.filter(user1=user1, user2=user2).delete() 
 
class Friendship(TimeStampedModel): 
    user1 = models.ForeignKey( 
        User,  
        related_name='friendships_initiated',  
        on_delete=models.CASCADE 
    ) 
    user2 = models.ForeignKey( 
        User,  
        related_name='friendships_received',  
        on_delete=models.CASCADE 
    ) 
     
    objects = FriendshipManager() 
     
    class Meta: 
        unique_together = ('user1', 'user2') 
        indexes = [ 
            models.Index(fields=['user1']), 
            models.Index(fields=['user2']), 
            models.Index(fields=['created_at']), 
        ] 
     
    def clean(self): 
        if self.user1 == self.user2: 
            raise ValidationError("Cannot be friends with yourself.") 
        # Enforce ordering user1.id < user2.id 
        if self.user1.id > self.user2.id: 
            self.user1, self.user2 = self.user2, self.user1 
     
    def save(self, *args, **kwargs): 
        self.clean() 
        super().save(*args, **kwargs) 
     
    def __str__(self): 
        return f"{self.user1.username} ↔ {self.user2.username}" 
 
class Group(TimeStampedModel): 
    name = models.CharField(max_length=100, db_index=True) 
    description = models.TextField(default='', blank=True) 
    created_by = models.ForeignKey( 
        User,  
        on_delete=models.CASCADE,  
        related_name='groups_created' 
    ) 
    members = models.ManyToManyField(User, related_name='groups_joined', blank=True) 
    is_active = models.BooleanField(default=True) 
     
    class Meta: 
        indexes = [ 
            models.Index(fields=['name']), 
            models.Index(fields=['created_by']), 
            models.Index(fields=['is_active']), 
            models.Index(fields=['created_at']), 
        ] 
     
    def __str__(self): 
        return f"Group: {self.name} (Created by {self.created_by.username})" 
     
    @property 
    def member_count(self): 
        return self.members.count() 
 
class GroupInvitation(TimeStampedModel): 
    STATUS_CHOICES = [ 
        ('pending', 'Pending'), 
        ('accepted', 'Accepted'), 
        ('declined', 'Declined') 
    ] 
     
    group = models.ForeignKey( 
        Group,  
        on_delete=models.CASCADE,  
        related_name='invitations' 
    ) 
    invited_user = models.ForeignKey( 
        User,  
        on_delete=models.CASCADE,  
        related_name='group_invitations' 
    ) 
    invited_by = models.ForeignKey( 
        User,  
        on_delete=models.CASCADE,  
        related_name='sent_group_invitations' 
    ) 
    status = models.CharField( 
        max_length=10, 
        choices=STATUS_CHOICES, 
        default='pending', 
        db_index=True 
    ) 
    expires_at = models.DateTimeField(null=True, blank=True) 
     
    class Meta: 
        unique_together = ('group', 'invited_user') 
        indexes = [ 
            models.Index(fields=['invited_user', 'status']), 
            models.Index(fields=['group', 'status']), 
            models.Index(fields=['expires_at']), 
        ] 
     
    def clean(self): 
        if self.invited_user == self.invited_by: 
            raise ValidationError("Cannot invite yourself.") 
     
    def save(self, *args, **kwargs): 
        self.clean() 
        super().save(*args, **kwargs) 
     
    def __str__(self): 
        return f"Invitation to {self.invited_user.username} for group {self.group.name} ({self.status})" 
     
    @property 
    def is_expired(self): 
        if not self.expires_at: 
            return False 
        from django.utils import timezone 
        return timezone.now() > self.expires_at